#include <iostream>

using namespace std;

int main()
{
    int n;
    int v[n] = {};

    cin>>n;
    int k = 0; // numara cate zerouri am
    for (int i = 0; i<=n-1;i++)
        cin>>v[i];

    for (int i = 0; i<= n-1; i++) {
        if (v[i] < 0)
            {
                for (int j = i; j <=n-2; j++) {
                v[j+1] = v[j];
                v[i] = 0;

            }
            k++;
            }
    }

    for (int i = 0 ; i<= n-1 + k; i++) {
        cout<< v[i]<<" ";
    }
    return 0;
}
