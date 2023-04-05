#include <fstream>
#include <cstring>
#include <stdio.h>

using namespace std;

int n;

int main()
{
    ifstream f("date.in");
    ofstream g("date.out");

    f>>n;
    while (true) {
        int r;
        r = n%2;
        g<<r;
    }
}
