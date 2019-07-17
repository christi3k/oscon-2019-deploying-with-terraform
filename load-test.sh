#!/bin/bash

for i in {0..500};
do
   echo -n "$RANDOM" | faas-cli invoke primes && echo;
done;
