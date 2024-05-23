////////////////////////////////////////////////////////////////////////////////////////
// Basic settings for this script
////////////////////////////////////////////////////////////////////////////////////////

// port for listening to incoming OSC data
~osc_IN         = 6666;

// this determines how many sources (and inputs) we have
~n_inputs       = 32;

// the HOA order determines the size of the HOA bus and the nr of outputs
~hoa_order      = 5;
~n_hoa_channels = (pow(~hoa_order + 1.0 ,2.0)).asInteger;

////////////////////////////////////////////////////////////////////////////////////////
// Server options
////////////////////////////////////////////////////////////////////////////////////////

s.options.device               = "litespat";
s.options.numInputBusChannels  = ~n_inputs;
s.options.numOutputBusChannels = ~n_hoa_channels;
s.options.memSize              = 65536;
s.options.numBuffers           = 4096;

////////////////////////////////////////////////////////////////////////////////////////
// Start of main routine for setting up the spatial renderer
////////////////////////////////////////////////////////////////////////////////////////

s.waitForBoot({


	////////////////////////////////////////////////////////////////////////////////////
	// This is the SynthDef for the encoders

	SynthDef(\hoa_mono_encoder,
		{
			|
			in_bus  = nil,
			out_bus = 0,
			azim    = 0,
			elev    = 0,
			dist    = 0.1,
			gain    = 1
			|


			var sound = gain * SoundIn.ar(in_bus);
			var level =  (20.0 / (max(0.01,dist)+1.0))*(1.0 / ( max(0.01,dist)+20.0));
			var bform = HOASphericalHarmonics.coefN3D(~hoa_order, azim, elev) * sound * level;

			Out.ar(out_bus, bform);

	}).add;

	////////////////////////////////////////////////////////////////////////////////////////
	// use server sync after asynchronous commands
	s.sync;


	////////////////////////////////////////////////////////////////////////////////////////
	// The group for the spatial encoders
	~spatial_GROUP = Group.after(~input_GROUP);
	s.sync;

	////////////////////////////////////////////////////////////////////////////////////////
	// a multichannel audio bus for the encoded Ambisonics signal
	~ambi_BUS = Bus.audio(s, ~n_hoa_channels);


	////////////////////////////////////////////////////////////////////////////////////////
	// create all encoders in a loop
	for (0, ~n_inputs
		-1, {arg i;

			post('Adding HOA encoder module: ');
			i.postln;

			// this is the array of encoders
			~hoa_panners = ~hoa_panners.add(
				Synth(\hoa_mono_encoder,
					[
						\in_bus,  i,
						\out_bus, ~ambi_BUS.index
					],
					target: ~spatial_GROUP
			);)
	});
	s.sync;

	////////////////////////////////////////////////////////////////////////////////////////
	// a reverb node


	~reverb = {

		|
		gain = 0.4,
		room = 0.1,
		damp = 0.2
		|

		var inchan = Array.fill(~n_inputs,{arg i; i});

		Out.ar(0,FreeVerb.ar(Mix.ar(SoundIn.ar(inchan)),1,room,damp,gain));
		Out.ar(1,FreeVerb.ar(Mix.ar(SoundIn.ar(inchan)),1,room,damp*1.05,gain));
		Out.ar(2,FreeVerb.ar(Mix.ar(SoundIn.ar(inchan)),1,room,damp*0.95,gain));
		Out.ar(3,FreeVerb.ar(Mix.ar(SoundIn.ar(inchan)),1,room,damp,gain));

	}.play;

	s.sync;

	~reverb.set(\gain,0.5);
	~reverb.set(\room,0.6);
	~reverb.set(\damp,0.15);

	////////////////////////////////////////////////////////////////////////////////////////
	// Another group for the outputs
	////////////////////////////////////////////////////////////////////////////////////////

	~output_GROUP	 = Group.after(~spatial_GROUP);
	s.sync;

	////////////////////////////////////////////////////////////////////////////////////////
	// The output node
	////////////////////////////////////////////////////////////////////////////////////////

	~hoa_output = {|gain=1| Out.ar(0 ,gain * In.ar(~ambi_BUS.index,~n_hoa_channels))}.play;
	s.sync;
	// goes into the output group
	~hoa_output.moveToTail(~output_GROUP);
	~hoa_output.set(\gain,0.75);



	////////////////////////////////////////////////////////////////////////////////////////
	// One OSC listener for data from the Quest 3
	////////////////////////////////////////////////////////////////////////////////////////

	OSCdef('/src/aed',
		{
			arg msg, time, addr, recvPort;
			var a,e,d;
			var x,y,z;

			var idx;


			idx = msg[1]-1;

			~hoa_panners[idx].set(\azim, -1 * msg[2]);
			~hoa_panners[idx].set(\elev, msg[3]);
			~hoa_panners[idx].set(\dist, msg[4]);

/*			if(idx==0){
				msg.postln}{};*/

	},'/src/aed');


	OSCdef('/src/xyz',
		{

			arg msg, time, addr, recvPort;
			var a,e,d;
			var x,y,z;


			var c;

			if(msg[2]=='src1:',{

				x = msg[4];
				y = msg[5];
				z = msg[6];

				c	= Cartesian(x,y,z);

				~hoa_panners[0].set(\azim, c.theta());
				~hoa_panners[0].set(\elev, c.phi());
				~hoa_panners[0].set(\dist, c.rho());

				//msg.postln;

			},{});

	},'/src/xyz');

	////////////////////////////////////////////////////////////////////////////////////////
	// One OSC listener function for each spatial paramter
	////////////////////////////////////////////////////////////////////////////////////////

	OSCdef('/source/azim',
		{
			arg msg, time, addr, recvPort;
			var azim = msg[2];

			~hoa_panners[msg[1]].set(\azim, azim);
			postln("Azimuth: "+azim)

	},'/source/azim');

	OSCdef('/source/elev',
		{
			arg msg, time, addr, recvPort;
			var elev = msg[2];

			~hoa_panners[msg[1]].set(\elev,elev);
			postln("Elevation: "+elev)

	}, '/source/elev');

	OSCdef('/source/dist',
		{
			arg msg, time, addr, recvPort;
			var dist = msg[2];

			~hoa_panners[msg[1]].set(\dist,dist);
			postln("Distance: "+dist)

	}, '/source/dist');


	// open our extra ports for OSC and give feedback
	thisProcess.openUDPPort(~osc_IN);
	postln("Listening for OSC on ports: "++thisProcess.openPorts);

});
