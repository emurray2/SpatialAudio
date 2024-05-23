tmux new-session -d -s my_litespat

# Control patch
tmux send-keys -t my_litespat:0.0 'pd -jack -channels 8 PureData/tracking_parser.pd' C-m

tmux split-window -h -t my_litespat
tmux send-keys -t my_litespat:0.1 'scide SuperCollider/litespat_server.sc' C-m

tmux split-window -h -t my_litespat
tmux send-keys -t my_litespat:0.2 'iem-plugin-allradecoder -loadSettings IEM/AllRADecoder.settings' C-m

sleep 5

tmux split-window -h -t my_litespat
tmux send-keys -t my_litespat:0.3 'aj-snapshot -x -d setup/litespat_couch.snap' C-m

tmux select-layout -t my_litespat tiled

tmux attach-session -t my_litespat


# enter "exit" to kill the corresponding window you want to delete
# enter tmux send-keys -t my_litespat:0.x(the number depends on the configuration) 'cd path to the file && the file you want to execute' C-m
# remember to add pd -nogui before the pd file path tp execute it correctly
