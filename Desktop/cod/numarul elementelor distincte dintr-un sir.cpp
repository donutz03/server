#include <iostream>

using namespace std;

int t[5];

int f (int t[10000] , int n)
{
    int i = 0 , s = 0 ;
        while ( i < n) {
            int j = i + 1 ;
            while ( j < n && t [ i ] == t [ j ] )
            {j += 1 ;}
            s += 1 ;
            i = j ;
}
return s ;
}

int main()
{
    for (int i=1;i<=4;i++)
        cin>>t[i];
    cout<<f(t,4);
    return 0;
}
