#include <iostream>
#include <cstring>


using namespace std;

int i,j,k=2;
char s[20]="aaabbcdaaa";

int getAnagram(string s)
{char s1[100000]="\0", s2[100000]="\0";
     int j=strlen(s)/2;
     int op=0;
     strncpy(s1,s,strlen(s)/2);
     strcpy(s2,s+strlen(s)/2);
     int char_count[10];

        for (int i = 0; i < 10; i++)
        {
            char_count[i] = 0;
        }

        for (int i = 0; i < j; i++)
            char_count[s1[i] - 'a']++;

        for (int i = 0; i < j; i++)
        {
            char_count[s2[i] - 'a']--;
        }

        for(int i = 0; i < 26; ++i)
        {
          if(char_count[i] != 0)
          {
            op+=abs(char_count[i]);
          }
        }
        cout<< op / 2;
}



int main()
{
  cout<<getAnagram(s)<<endl;
  cout<<strlen(s);

}
