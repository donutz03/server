#include <iostream>

using namespace std;

int main()
{
    int i, j, nr=0, a[100][100];

    for (i=1; i<=50;i++)
    {
        for(j=1;j<=50;j++)
            {if (((50*(i-1)+j)%7==0) || ((50*(i-1)+j)%13==0))
                a[i][j]=1;
            else
                a[i][j]=0;
            }
    }

     for (i=1; i<=50;i++)
    {
        for(j=1;j<=49;j++)
        {
         if((a[i][j]==0 && a[i][j+1]==0))
            nr++;
        }
    }
     for (i=1; i<=49;i++)
    {
        for(j=1;j<=50;j++)
        {
            if((a[i][j]==0 && a[i+1][j]==0))
            nr++;
        }
    }

    cout<<nr;

    /*
     for (i=1; i<=50;i++)
    {
        for(j=1;j<=50;j++)
        {
            cout<<a[i][j]<<" ";
        }
        cout<<endl;
    }
    */
    return 0;
}
