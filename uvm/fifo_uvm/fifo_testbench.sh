# compile only 
make compile

# run the random test
make sim

# run with a specific test
make sim TEST=fifo_random_test

# change verbosity for debug
make sim VERBOSITY=UVM_HIGH

# clean everything
make clean