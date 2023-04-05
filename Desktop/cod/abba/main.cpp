#include<iostream>
using namespace std;
int main( )
{
int n, cn, x=0,p=1;
cin>>n;
cn=n;
while(n)
{
 if (n%10>x)x=n%10;
 n/=10;
}
x++;
while(cn)
 {
 n=n+cn%10*p;
 p*=x;
 cn/=10;
 }
cout<<n;
}
