#include<stdio.h>
#include<string.h>
#include<errno.h>
#include<stdlib.h>
#include"object.h"
#include<assert.h>

/* 简单的错误处理函数：打印信息并退出（与 ex18 中的实现类似） */
static void die(const char *message)
{
    if (errno) {
        perror(message);
    } else {
        printf("ERROR: %s\n", message);
    }

    exit(1);
}

void Object_destroy(void *self)
{
    assert(self != NULL);
    Object *obj = self;
    /* 因为前面已经 assert(self != NULL)，obj 不会为 NULL */
    if (obj->description) free(obj->description);
    free(obj);
    
}

void Object_describe(void *self)
{
    assert(self != NULL);
    Object *obj = self;
    assert(obj->description != NULL);

    printf("%s.\n", obj->description);
}

int Object_init(void *self)
{
    assert(self != NULL);
    // do nothing really
    return 1;
}

void *Object_move(void *self, Direction direction)
{
    assert(self != NULL);
    printf("You can't go that direction.\n");
    return NULL;
}

int Object_attack(void *self, int damage)
{
    assert(self != NULL);
    printf("You can't attack that.\n");
    return 0;
}

void *Object_new(size_t size, Object proto, char *description)
{
    assert(size >= sizeof(Object));
    assert(description != NULL);

    //setup the default functions in case they aren't set
    if(!proto.init) proto.init = Object_init;
    if(!proto.describe) proto.describe = Object_describe;
    if(!proto.destroy) proto.destroy = Object_destroy;
    if(!proto.attack) proto.attack = Object_attack;
    if(!proto.move) proto.move = Object_move;

    // this seems weird, but we can make a struct of one size,
    // then point a different pointer at it to "cast" it
    Object *el = calloc(1, size);
    if (!el) die("Memory error");

    /* 把 proto（Object 头）拷贝到新分配内存的起始处 */
    *el = proto;

    /* 复制描述字符串并检查 */
    el->description = strdup(description);
    if (!el->description) {
        free(el);
        die("Memory error");
    }

    // initiallize it with whatever init we were given
    if(!el->init(el)) {
        // looks like it didn't initialize properly
        el->destroy(el);
        return NULL;
    } else {
        // all done, we made an object of any type
        return el;
    }
}