#include <iostream>

using namespace std;

int k,i,d,p,n,e;

int main()
{
    k=0;
cin>>n;
d=2;p=1;
while(d*d<=n)
{
e=0;
while(n%d==0)
{
e++;
n=n/d;
}
p=p*(e+1);
d++;
cout<<p<<endl;
}
if(n>1)p=p*2;
if(p%2==0) k++;

cout<<k<<endl;

    return 0;
}
