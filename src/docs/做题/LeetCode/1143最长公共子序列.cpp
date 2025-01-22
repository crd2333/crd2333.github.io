/*
https://leetcode.cn/problems/longest-common-subsequence/solutions/696763/zui-chang-gong-gong-zi-xu-lie-by-leetcod-y7u0/ (1143. 最长公共子序列)
DP，最简单的一集
*/

#include "Allinclude.h"

class Solution {
public:
    int longestCommonSubsequence(string text1, string text2) {
        int N = max(text1.size(), text2.size());
        int dp[N+1][N+1];
        memset(dp, 0, sizeof(dp));
        for (int i = 1; i <= text1.size(); i++) {
            for (int j = 1; j <= text2.size(); j++) {
                if (text1[i-1] == text2[j-1])
                    dp[i][j] = dp[i-1][j-1] + 1;
                else
                    dp[i][j] = max(dp[i-1][j], dp[i][j-1]);
            }
        }
        return dp[text1.size()][text2.size()];
    }
};

int main() {
    string str1, str2;
    cin >> str1 >> str2;
    Solution s;
    cout << s.longestCommonSubsequence(str1, str2) << endl;
}
