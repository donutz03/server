#include <iostream>


using namespace std;

int x,b,z,l,an=2021,o,m,nr=528480,i,j,a[600000][5],n=535679;



    int data_valida (int z, int l, int o, int m)
    {
        if (z>=1 && z<=28 && l==2 && o>=0 && o<=23 && m>=0 && m<=59)
            return 1;
        else if ((l==1 || l==3 || l==5 || l==7 || l==8 || l==10 || l==12) && z>=1 && z<=31 && o>=0 && o<=23 && m>=0 && m<=59)
            return 1;
        else if ((l==4 || l==6 || l==9 || l==11) && z>=1 && z<=30 && o>=0 && o<=23 && m>=0 && m<=59)
            return 1;
        else return 0;
    }


int main()
{


    for (i=0;i<=535679;i++)
    {
        for (j=0;j<=3;j++)
        {
        if (j==0)
            a[i][j]=i%31+1;
        if (j==1)
            a[i][j]=i%12+1;
        if (j==2)
            a[i][j]=i%24;
        if (j==3)
            a[i][j]=i%60;
        }
    }
    cout<<nr<<" ";
for (i=0;i<=535679;i++)
    {
           if (data_valida(a[i][0],a[i][1],a[i][3],a[i][2]) || data_valida(a[i][0],a[i][2],a[i][1],a[i][3]) || data_valida(a[i][0],a[i][2],a[i][3],a[i][1]) || data_valida(a[i][0],a[i][3],a[i][1],a[i][2]) || data_valida(a[i][0],a[i][3],a[i][2],a[i][1]) || data_valida(a[i][1],a[i][0],a[i][2],a[i][3]) || data_valida(a[i][1],a[i][0],a[i][3],a[i][2]) || data_valida(a[i][1],a[i][2],a[i][0],a[i][3]) || data_valida(a[i][1],a[i][2],a[i][3],a[i][0]) || data_valida(a[i][1],a[i][3],a[i][0],a[i][2]) || data_valida(a[i][1],a[i][3],a[i][2],a[i][0]) || data_valida(a[i][2],a[i][0],a[i][1],a[i][3]) || data_valida(a[i][2],a[i][0],a[i][3],a[i][1])|| data_valida(a[i][2],a[i][1],a[i][0],a[i][3]) || data_valida(a[i][2],a[i][1],a[i][3],a[i][0]))
        {

        nr--;
        }
 /* if (data_valida(a[i][0],a[i][2],a[i][1],a[i][3]))
        {
        a[i][0]=0;
        a[i][1]=0;
        a[i][2]=0;
        a[i][3]=0;
        nr--;
        }

           if (data_valida(a[i][0],a[i][2],a[i][3],a[i][1]))
        {
        a[i][0]=0;
        a[i][1]=0;
        a[i][2]=0;
        a[i][3]=0;
        nr--;
        }

           if (data_valida(a[i][0],a[i][3],a[i][1],a[i][2]))
        {
        a[i][0]=0;
        a[i][1]=0;
        a[i][2]=0;
        a[i][3]=0;
        nr--;
        }
           if (data_valida(a[i][0],a[i][3],a[i][2],a[i][1]))
        {
        a[i][0]=0;
        a[i][1]=0;
        a[i][2]=0;
        a[i][3]=0;
        nr--;
        }
    if (data_valida(a[i][1],a[i][0],a[i][2],a[i][3]))
        {
        a[i][0]=0;
        a[i][1]=0;
        a[i][2]=0;
        a[i][3]=0;
        nr--;
        }

         if (data_valida(a[i][1],a[i][0],a[i][3],a[i][2]))
        {
        a[i][0]=0;
        a[i][1]=0;
        a[i][2]=0;
        a[i][3]=0;
        nr--;
        }
        if (data_valida(a[i][1],a[i][0],a[i][2],a[i][3]))
        {
        a[i][0]=0;
        a[i][1]=0;
        a[i][2]=0;
        a[i][3]=0;
        nr--;
        }
            if (data_valida(a[i][1],a[i][0],a[i][3],a[i][2]))
        {
        a[i][0]=0;
        a[i][1]=0;
        a[i][2]=0;
        a[i][3]=0;
        nr--;
        }
   if (data_valida(a[i][1],a[i][2],a[i][0],a[i][3]))
        {
        a[i][0]=0;
        a[i][1]=0;
        a[i][2]=0;
        a[i][3]=0;
        nr--;
        }
if (data_valida(a[i][1],a[i][2],a[i][3],a[i][0]))
        {
        a[i][0]=0;
        a[i][1]=0;
        a[i][2]=0;
        a[i][3]=0;
        nr--;
        }
if (data_valida(a[i][1],a[i][3],a[i][0],a[i][2]))
        {
        a[i][0]=0;
        a[i][1]=0;
        a[i][2]=0;
        a[i][3]=0;
        nr--;
        }
        if (data_valida(a[i][1],a[i][3],a[i][2],a[i][0]))
        {
        a[i][0]=0;
        a[i][1]=0;
        a[i][2]=0;
        a[i][3]=0;
        nr--;
        }
        if (data_valida(a[i][2],a[i][0],a[i][1],a[i][3]))
        {
        a[i][0]=0;
        a[i][1]=0;
        a[i][2]=0;
        a[i][3]=0;
        nr--;
        }
        if (data_valida(a[i][2],a[i][0],a[i][3],a[i][1]))
        {
        a[i][0]=0;
        a[i][1]=0;
        a[i][2]=0;
        a[i][3]=0;
        nr--;
        }
         if (data_valida(a[i][2],a[i][1],a[i][0],a[i][3]))
        {
        a[i][0]=0;
        a[i][1]=0;
        a[i][2]=0;
        a[i][3]=0;
        nr--;
        }
    }
*/

 /* for (i=0;i<=535679;i++)
    {
        for (j=0;j<=3;j++)
        {
            cout<<a[i][j]<<" ";
        }
        cout<<endl;
    }

    return 0;*/
}
cout<<nr;
}
