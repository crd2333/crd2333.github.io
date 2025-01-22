// 很粗暴的贪心，自己居然没做出来

#include "Allinclude.h"

class Solution {
public:
    int candy(vector<int>& ratings) {
        int size = ratings.size();
        if (size < 2)
            return size;
        vector<int> num(size, 1); // 初始化大小为 size，默认赋值为 1
        for (int i = 0; i < size - 1; ++i) {
            if (ratings[i + 1] > ratings[i])
                num[i + 1] = num[i] + 1;
        }
        for (int i = size - 1; i > 0; --i) {
            if (ratings[i - 1] > ratings[i] && num[i - 1] <= num[i])
                num[i - 1] = num[i] + 1;
        }
        // std::accumulate 可以很方便地求和
        return accumulate(num.begin(), num.end(), 0);
    }
};
