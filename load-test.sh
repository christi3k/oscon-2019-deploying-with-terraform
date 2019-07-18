#!/bin/bash

for i in {0..2000};
do
   echo -n "$RANDOM" | faas-cli invoke primes && echo;
done;
