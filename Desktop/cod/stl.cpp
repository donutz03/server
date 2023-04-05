#include <iostream>
#include <vector>
#include <algorithm>
#include <map>
#include <set>

using namespace std;

bool f(int x, int y){
    return x > y;
}

void vectorDemo()
{
vector<int> A = {11, 2, 3, 14};

cout << A[1] << endl;

sort(A.begin(), A.end()); //(O(NlogN))

//2,3,11,14
//O(logN)
bool present = binary_search(A.begin(), A.end(), 3); //true 
present = binary_search(A.begin(), A.end(), 4); //false

A.push_back(100);
present = binary_search(A.begin(), A.end(), 100); //true

//2, 3, 11, 14, 100
A.push_back(100);
A.push_back(100);
A.push_back(100);
A.push_back(100);

//2, 3, 11, 14, 100, 100, 100, 100, 100, 123
A.push_back(123);

auto it = lower_bound(A.begin(), A.end(), 100); // >= 
auto it2 = upper_bound(A.begin(), A.end(), 100); // >

cout << *it << " " << *it2 << endl; 
cout << it2 - it;  // 5
cout << endl;

sort(A.begin(), A.end(), f);
for (int &x: A)  
{
    x++;
    cout << x << " ";
}
cout << endl;

for (int x: A)  
{
    x++;
    cout << x << " ";
}
cout << endl; 
}

void setDemo()
{
    set<int> S;
    S.insert(1);
    S.insert(2);
    S.insert(-1);
    S.insert(-10);

    for (int x: S)
        cout << x << " ";
    cout <<endl;

    //-10 -1 1 2

    auto it = S.find(-1);
    if (it == S.end())
    {
        cout << "not present\n";
    }
    else
    {
        cout << "present\n";
        cout << *it << endl;
    }

    auto it2 = S.upper_bound(-1);
    auto it3 = S.upper_bound(0);
    cout << *it2 << " " << *it3 << endl;

    auto it4 = S.upper_bound(2);
    if (it4 == S.end())
    {
        cout << "oops! sorry cant find something like that\n";
    }

    S.erase(1);
}

void mapDemo()
{
    map<int, int> A;
    A[1] = 100;
    A[2] = -1;
    A[3] = 200;
    A[100000232] = 1;

    map<char, int> cnt;
    string x = "rachit jain";
    
    for (char c : x){
        cnt[c]++;
    }
    cout << cnt['a'] << " " << cnt['z'] << endl;

    //in log(N) time: A.find(key) and A.erase(key)

}

void PowerOfStl()
{
    // [x , y] 
    /*add [2, 3]
        add [10, 20]
        add [30, 400]
        add [401, 450]
        give me the interval 13*/

    set<pair<int, int> >S;

    S.insert({401, 450});
     S.insert({10, 20}); 
    S.insert({2, 3});  
    S.insert({30, 400});  
    
    //2, 3
    //10, 20
    //30, 400
    //401, 450

    int point = 1;

    auto it = S.upper_bound({point, INT_MAX});
    if(it == S.begin())
    {
          cout << "the given point is not lying in any interval..\n";
          return;
    }
    it--;
    pair<int, int> current = *it;
    if(current.first <= point && point <= current.second){
        cout << "yes its present: " << current.first << " " << current.second << endl;
    }
    else
    {
        cout << "the given point is not lying in any interval..\n";
    }

}

int main()
{
    //C++ STL
    mapDemo();

}