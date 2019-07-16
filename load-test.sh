#!/bin/bash

for i in {0..5000};
do
   echo -n "$RANDOM" | faas-cli invoke primes && echo;
done;
