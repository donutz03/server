#include <iostream>

using namespace std;

unsigned ex(unsigned n)
{ unsigned a;
if (n == 0) return 9;
else
{ a= ex(n / 10);
if ( n % 10 < a )
return n%10;
return a;
}
}

int main()
{
    cout<<ex(256);
    return 0;
}
