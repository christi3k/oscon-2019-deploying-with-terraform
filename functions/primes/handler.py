import math


def handle(req):
    """handle a request to the function
    Args:
        req (str): request body
    """
    number = int(req)
    prime_factors = primeFactors(number)
    return prime_factors

# A function to print all prime factors of  
# a given number n 
def primeFactors(n): 
    primes = []  
    # Print the number of two's that divide n 
    while n % 2 == 0: 
        primes.append(2)
        n = n / 2
          
    # n must be odd at this point 
    # so a skip of 2 ( i = i + 2) can be used 
    for i in range(3,int(math.sqrt(n))+1,2): 
          
        # while i divides n , print i ad divide n 
        while n % i== 0: 
            primes.append(i)
            n = n / i 
              
    # Condition if n is a prime 
    # number greater than 2 
    if n > 2: 
        primes.append(n)

    return primes
