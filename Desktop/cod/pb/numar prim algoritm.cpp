#include <iostream>
#include <cmath>

using namespace std;


int main ()
{
int n=0,i=1,j=1,prim=0,c=0;

cout<<98731%37<<endl;
    cout<<"n:"; cin>>n;
    cout<<"numerele prime de la "<<i<<" la "<<n<<" sunt : ";
    for(i=99999;i>=90000;i--)
        {
        for(j=1;j<=n;j++)
            if(i%j==0)
            {
            c++;
            }
            if(c==2)
            {
            prim=i;
            cout<<prim<<" ";
            }
         c=0;
        }
}



   /* for (i=99999;i>=10000;i--)
    {
        if(i/10000!=i/1000%10 && i/10000!=i/100%10 && i/10000!=i/10%10 && i/10000!=i%10 && i/1000%10!=i/100%10 && i/1000%10!=i/10%10 && i/1000%10!= i%10 && i/100%10!=i/10%10 && i/100%10!=i%10 && i/10%10!=i%10 && i%10!=i/10000)
            {
                for(k=2;k<=sqrt(i);k++)
        {
            if(i%k==0)
                nr++;
        }
        if (nr==0)
            a[j]=i;
            j++;
            }
    }

    for (j=0;j<=10000;j++)
        cout<<a[j]<<" "<<endl;*/

