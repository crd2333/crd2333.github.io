// 很粗暴的贪心

#include "Allinclude.h"

class Solution {
public:
    int eraseOverlapIntervals(vector<vector<int>>& intervals) {
        sort(intervals.begin(), intervals.end(), [](vector<int> vec1, vector<int> vec2) { return vec1[1] < vec2[1]; });
        int res = 1;
        int last = intervals[0][1];
        for (auto iter = intervals.begin() + 1; iter != intervals.end(); iter++) {
            if ((*iter)[0] >= last) {
                res++;
                last = (*iter)[1];
            }
        }
        return intervals.size() - res;
    }
};
