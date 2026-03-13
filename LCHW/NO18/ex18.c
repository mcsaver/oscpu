#include<stdio.h>
#include<stdlib.h>
#include<errno.h>
#include<string.h>

/* Our old friend die from ex17
   发生错误时打印信息并退出程序 */
void die(const char * message)
{
    if (errno)
    {
        /* 如果 errno 被设置，使用 perror 打印系统错误信息 */
        perror(message);
    } else {
        /* 否则打印自定义错误信息 */
        printf("ERROR: %s\n", message);
    }
    
    exit(1);
}

/* typedef 定义了一个函数指针类型 compare_cb，
   表示比较两个 int 的函数，返回 int（>0、=0、<0） */
typedef int (*compare_cb)(int a, int b);

/* 新增 typedef：排序函数类型，接收数组、长度和比较回调，返回新分配的已排序数组 */
typedef int *(*sort_cb)(int *numbers, int count, compare_cb cmp);

/* 经典的冒泡排序函数，使用 compare_cb 进行比较。
   返回一个新分配的已排序数组（调用者负责 free）。 */
int *bubble_sort(int *numbers, int count, compare_cb cmp)
{
    int temp = 0;
    int i = 0;
    int j = 0;
    int *target = malloc(count * sizeof(int));

    if(!target) die("Memory error.");

    /* 复制原数组到 target，避免修改原数组 */
    memcpy(target, numbers, count * sizeof(int));

    for ( i = 0; i < count; i++)
    {
        for ( j = 0; j < count - 1; j++)
        {
            /* 使用回调函数 cmp 决定是否交换 */
            if (cmp(target[j], target[j+1]) > 0)
            {
                temp = target[j+1];
                target[j+1] = target[j];
                target[j] = temp;
            }
            
        }
        
    }
    
    return target;
}

/* 新增：选择排序（同样返回新分配数组） */
int *selection_sort(int *numbers, int count, compare_cb cmp)
{
    int i, j, min_idx;
    int temp;
    int *target = malloc(count * sizeof(int));
    if(!target) die("Memory error.");

    memcpy(target, numbers, count * sizeof(int));

    for (i = 0; i < count - 1; i++) {
        min_idx = i;
        for (j = i + 1; j < count; j++) {
            if (cmp(target[min_idx], target[j]) > 0) {
                min_idx = j;
            }
        }
        if (min_idx != i) {
            temp = target[i];
            target[i] = target[min_idx];
            target[min_idx] = temp;
        }
    }

    return target;
}

/* 正常顺序比较函数：升序 */
int sort_order(int a, int b)
{
    return a - b;
}

/* 反序比较函数：降序 */
int reverse_order(int a, int b)
{
    return b - a;
}

/* 奇怪的比较函数：
   如果任一为 0 返回 0（表示相等，不交换），否则返回 a % b。
   注意：这不是一个严格的比较函数（不保证传递性/对称性），
   主要用于演示不同的比较行为。 */
int strange_order(int a, int b)
{
    if (a == 0 || b == 0)
    {
        return 0;
    } else {
        return a % b;
    }
    
}

/* 修改：用于测试排序，接收任意排序函数 sort 和比较回调 cmp */
void test_sorting(int *numbers, int count, sort_cb sort, compare_cb cmp)
{
    int i = 0;
    int *sorted = sort(numbers, count, cmp);

    if(!sorted) die("Failed to sort as requested.");

    /* 打印排序结果，数字之间用空格分隔 */
    for ( i = 0; i < count; i++)
    {
        printf("%d ", sorted[i]);
    } 

    printf("\n");

    free(sorted);
}

int main(int argc, char *argv[])
{
    if(argc < 2) die("USAGE: ex18 4 3 1 5 6");

    int count = argc - 1;
    int i = 0;
    char **inputs = argv + 1;

    int *numbers = malloc(count * sizeof(int));
    if(!numbers) die("Memory error.");

    for ( i = 0; i < count; i++)
    {
        /* 将命令行字符串转换为整数 */
        numbers[i] = atoi(inputs[i]);
    }
    
    /* 使用两种排序算法和三种比较函数分别测试 */
    printf("bubble_sort, sort_order:\n");
    test_sorting(numbers, count, bubble_sort, sort_order);

    printf("selection_sort, sort_order:\n");
    test_sorting(numbers, count, selection_sort, sort_order);

    printf("bubble_sort, reverse_order:\n");
    test_sorting(numbers, count, bubble_sort, reverse_order);

    printf("selection_sort, reverse_order:\n");
    test_sorting(numbers, count, selection_sort, reverse_order);

    printf("bubble_sort, strange_order:\n");
    test_sorting(numbers, count, bubble_sort, strange_order);

    printf("selection_sort, strange_order:\n");
    test_sorting(numbers, count, selection_sort, strange_order);

    free(numbers);

    return 0;
}