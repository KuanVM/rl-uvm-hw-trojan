# compile only 
make compile

# run the random test
make sim

# run with a specific test
make sim TEST=fifo_test_random

# change verbosity for debug
make sim VERBOSITY=UVM_HIGH

# see the waveform
make wave

# clean everything
make clean