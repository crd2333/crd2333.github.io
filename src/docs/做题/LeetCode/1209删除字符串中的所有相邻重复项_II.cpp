/*
https://leetcode.cn/problems/remove-all-adjacent-duplicates-in-string-ii/ (1209. 删除字符串中的所有相邻重复项 II)
核心思路是使用栈，后进先出的特性使得它天然适合这种前后相连就删除的消消乐操作
*/

#include "Allinclude.h"

class Solution {
public:
    string removeDuplicates(string s, int k) {
        for (int i = 0; i < s.size(); i++) {
            char now = s[i];
            char prev = (i == 0) ? '#' : s[i-1];
            if (stack.empty() || now != prev)
                stack.push(1);
            else if (stack.top() >= k){
                s.erase(i - stack.top(), stack.top());
                i -= stack.top() + 1;
                multipop(stack.top());
                continue;
            }
            else
                stack.push(stack.top() + 1);
        }
        // deal with last strings
        int num = stack.top();
        if (num >= k) {
            multipop(num);
            s.erase(s.size() - num, num);
        }
        return s;
    }
private:
    stack<int> stack;
    void multipop(int k) {
        for (int i = 0; i < k; i++)
            stack.pop();
    }
};

int main() {
    int k;
    string str;
    cin >> str >> k;
    Solution s;
    cout << s.removeDuplicates(str, k);
}
/*
class Solution {
public:
    string removeDuplicates(string s, int k) {
        vector<pair<int, char>> count;
        for (int i = 0; i < s.length(); ++i) {
            if(count.empty() || s[i] != count.back().second){
                count.emplace_back(1, s[i]);
            }else {
                int num = ++count.back().first;
                if(num == k){
                    count.pop_back();
                }
            }
        }
        s = "";
        for(int i = 0; i < count.size(); i++){
            s += string(count[i].first, count[i].second);
        }
        return s;
    }
};
*/