#include <iostream>
#include<cstring>


using namespace std;
int i,a,x,b;
char c[20]="abcdefgh";

int main()
{
a=2019;
b=0;
for(x=1; x<=5; x++)
    a=a+2, b=b+5;

cout<<a<<" "<<b;



   // cout<<strchr(c, 'd')-c-1;
    return 0;
}
