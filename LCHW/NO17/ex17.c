#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <string.h>

/*
 * 这是一个小型的二进制数据库示例。
 * 思路：程序在内存中维护一个 Database 结构（包含若干 Address），
 * 并能将其保存到磁盘或从磁盘加载。
 * 每个 Address 包含 id、是否设置标志、以及两个动态分配的字符串缓冲（name/email），
 * 每个字符串的长度由数据库创建时的 max_data 决定。
 */

/* ---- 数据结构 ---- */

struct Address {
    int id;         /* 记录ID */
    int set;        /* 是否已设置（1） */
    char *name;     /* 动态缓冲，长度 = db->max_data */
    char *email;    /* 动态缓冲，长度 = db->max_data */
};

struct Database {
    int max_data;
    int max_rows;
    struct Address *rows; /* 动态数组 */
};

struct Connection {
    FILE *file;
    struct Database *db;
};

/*
 * 结构说明：
 * - Connection 用于封装文件句柄和内存中的 Database。
 * - Database 保存配置（每条记录的最大长度 max_data，记录数 max_rows）
 *   以及指向 Address 数组的指针 rows。
 * - 每个 Address 的 name/email 是通过 malloc 分配的固定长度缓冲。
 */

/* ---- 前置声明 ---- */
void die(struct Connection *conn, const char *message);
void Database_close(struct Connection *conn);
void Database_closep(struct Connection **pconn);

/* ---- 错误处理 ---- */

/* 打印错误并释放 conn（若有），然后退出 */
void die(struct Connection *conn, const char *message)
{
    if (errno) perror(message);
    else printf("ERROR: %s\n", message);

    Database_close(conn);
    exit(1);
}

/*
 * die: 当发生致命错误时调用。
 * - 如果 errno 非零，使用 perror 打印系统错误信息；否则打印自定义消息。
 * - 随后释放连接并退出程序。
 */

/* ---- 内存分配/释放 辅助 ---- */

/* 为 rows 分配并初始化字符串缓冲，失败返回 NULL */
static struct Address *alloc_rows(int max_rows, int max_data)
{
    struct Address *rows = malloc(sizeof(struct Address) * max_rows);
    if (!rows) return NULL;

    for (int i = 0; i < max_rows; i++) {
        /* 初始化每条记录的元数据并分配 name/email 缓冲 */
        rows[i].id = i; /* id 固定为索引，便于调试 */
        rows[i].set = 0; /* 初始为未设置 */
        rows[i].name = malloc(max_data); /* 为字符串分配固定长度 */
        rows[i].email = malloc(max_data);
        if (!rows[i].name || !rows[i].email) {
            /* 清理已分配的部分并返回失败 */
            for (int j = 0; j <= i; j++) {
                free(rows[j].name);
                free(rows[j].email);
            }
            free(rows);
            return NULL;
        }
        /* 将缓冲清零，确保字符串以 '\0' 结尾 */
        memset(rows[i].name, 0, max_data);
        memset(rows[i].email, 0, max_data);
    }
    return rows;
}

/* 释放单个 Address 的字符串缓冲 */
static void free_address_buffers(struct Address *a)
{
    if (!a) return;
    free(a->name);
    free(a->email);
}

/* 释放 Database（包含 rows 及其内部缓冲） */
static void free_database(struct Database *db)
{
    if (!db) return;
    if (db->rows) {
        for (int i = 0; i < db->max_rows; i++) {
            free_address_buffers(&db->rows[i]);
        }
        free(db->rows);
    }
    free(db);
}

/*
 * 注意内存释放顺序：先释放每个 Address 内部的 name/email，再 free rows 数组，
 * 最后 free Database 结构本身。
 */

/* ---- 关闭连接 ---- */

/* 释放并关闭，不修改调用者的指针 */
void Database_close(struct Connection *conn)
{
    if (!conn) return;
    if (conn->file) fclose(conn->file);
    if (conn->db) free_database(conn->db);
    free(conn);
}

/* 释放并把调用者的指针置 NULL */
void Database_closep(struct Connection **pconn)
{
    if (!pconn || !*pconn) return;
    Database_close(*pconn);
    *pconn = NULL;
}

/*
 * Database_closep: 接受 Connection 指针的地址（即 Connection**），释放并把外部指针置 NULL，
 * 这是防止悬空指针的一种常见做法。
 */

/* ---- IO：读/写数据库 ---- */

void Address_print(struct Address *addr)
{
    printf("%d %s %s\n", addr->id, addr->name, addr->email);
}

/* 简单打印一个 Address：id name email */

/* 从文件读取 header 并为 rows 分配缓冲，然后读取每条记录 */
void Database_load(struct Connection *conn)
{
    if (!conn || !conn->file) die(conn, "No connection for load");

    int max_rows, max_data;
    size_t rc = fread(&max_rows, sizeof(int), 1, conn->file);
    if (rc != 1) die(conn, "Failed to read max_rows");
    rc = fread(&max_data, sizeof(int), 1, conn->file);
    if (rc != 1) die(conn, "Failed to read max_data");

    conn->db->max_rows = max_rows;
    conn->db->max_data = max_data;

    /* 为 rows 分配内存（包括为每个 name/email 分配缓冲） */
    conn->db->rows = alloc_rows(conn->db->max_rows, conn->db->max_data);
    if (!conn->db->rows) die(conn, "Memory error");

    for (int i = 0; i < conn->db->max_rows; i++) {
    /* 每条记录以二进制方式按固定顺序存储：id, set, name(buffer), email(buffer) */
    rc = fread(&conn->db->rows[i].id, sizeof(int), 1, conn->file);
        if (rc != 1) die(conn, "Failed to read id");
        rc = fread(&conn->db->rows[i].set, sizeof(int), 1, conn->file);
        if (rc != 1) die(conn, "Failed to read set");

        rc = fread(conn->db->rows[i].name, 1, conn->db->max_data, conn->file);
        if (rc != (size_t)conn->db->max_data) die(conn, "Failed to read name");
        rc = fread(conn->db->rows[i].email, 1, conn->db->max_data, conn->file);
        if (rc != (size_t)conn->db->max_data) die(conn, "Failed to read email");

        /* 保证以 '\0' 终止 */
        conn->db->rows[i].name[conn->db->max_data - 1] = '\0';
        conn->db->rows[i].email[conn->db->max_data - 1] = '\0';
    }
}

/* 打开数据库：mode=='c' 则创建；否则打开并读取 */
struct Connection *Database_open(const char *filename, char mode, int max_rows, int max_data)
{
    struct Connection *conn = malloc(sizeof(struct Connection));
    if (!conn) die(NULL, "Memory error");
    conn->file = NULL;
    conn->db = NULL;

    /* 创建模式：初始化数据库结构并在磁盘上创建新文件 */
    if (mode == 'c') {
        if (max_rows <= 0 || max_data <= 0) die(conn, "Invalid max_rows or max_data for create");

        /* w+b: 可读写，若存在则截断，不存在则创建（二进制） */
        conn->file = fopen(filename, "w+b");
        if (!conn->file) {
            Database_close(conn);
            die(NULL, "Failed to open file for create");
        }

    /* 分配 Database 结构并设置基本参数 */
    conn->db = malloc(sizeof(struct Database));
        if (!conn->db) die(conn, "Memory error");
        conn->db->max_rows = max_rows;
        conn->db->max_data = max_data;

        conn->db->rows = alloc_rows(max_rows, max_data); /* 为每条记录分配缓冲 */
        if (!conn->db->rows) die(conn, "Memory error");
    } else {
        conn->file = fopen(filename, "r+b");
        if (!conn->file) {
            Database_close(conn);
            die(NULL, "Failed to open the file");
        }

    /* 打开现有文件：先创建 Database 结构，再加载数据到内存 */
    conn->db = malloc(sizeof(struct Database));
        if (!conn->db) die(conn, "Memory error");

        Database_load(conn);
    }

    return conn;
}

/* 将内存中数据库写回文件（包含 header） */
void Database_write(struct Connection *conn)
{
    if (!conn || !conn->file || !conn->db) die(conn, "No connection for write");

    rewind(conn->file);

    size_t rc = fwrite(&conn->db->max_rows, sizeof(int), 1, conn->file);
    if (rc != 1) die(conn, "Failed to write max_rows");
    rc = fwrite(&conn->db->max_data, sizeof(int), 1, conn->file);
    if (rc != 1) die(conn, "Failed to write max_data");

    /* 按固定顺序写入每条记录到文件；使用固定长度的字符串缓冲写入，便于随机访问 */
    for (int i = 0; i < conn->db->max_rows; i++) {
        rc = fwrite(&conn->db->rows[i].id, sizeof(int), 1, conn->file);
        if (rc != 1) die(conn, "Failed to write id");
        rc = fwrite(&conn->db->rows[i].set, sizeof(int), 1, conn->file);
        if (rc != 1) die(conn, "Failed to write set");

        /* 确保字符串有终止符并写入固定长度 buffer */
        conn->db->rows[i].name[conn->db->max_data - 1] = '\0';
        conn->db->rows[i].email[conn->db->max_data - 1] = '\0';

        rc = fwrite(conn->db->rows[i].name, 1, conn->db->max_data, conn->file);
        if (rc != (size_t)conn->db->max_data) die(conn, "Failed to write name");
        rc = fwrite(conn->db->rows[i].email, 1, conn->db->max_data, conn->file);
        if (rc != (size_t)conn->db->max_data) die(conn, "Failed to write email");
    }

    if (fflush(conn->file) == EOF) die(conn, "Cannot flush database.");
}

/* ---- 数据操作 ---- */

void Database_create(struct Connection *conn)
{
    if (!conn || !conn->db) die(conn, "No connection for create");

    /* 将每条记录初始化为未设置状态，清空 name/email 缓冲 */
    for (int i = 0; i < conn->db->max_rows; i++) {
        conn->db->rows[i].id = i;
        conn->db->rows[i].set = 0;
        memset(conn->db->rows[i].name, 0, conn->db->max_data);
        memset(conn->db->rows[i].email, 0, conn->db->max_data);
    }
}

void Database_set(struct Connection *conn, int id, const char *name, const char *email)
{
    if (!conn || !conn->db) die(conn, "No connection for set");
    if (id < 0 || id >= conn->db->max_rows) die(conn, "ID out of range");

    struct Address *addr = &conn->db->rows[id];
    if (addr->set) die(conn, "Already set, delete it first");

    addr->set = 1;
    /* 使用 strncpy 将输入复制到固定长度缓冲，并保证末尾有 '\0' */
    strncpy(addr->name, name, conn->db->max_data);
    addr->name[conn->db->max_data - 1] = '\0';
    strncpy(addr->email, email, conn->db->max_data);
    addr->email[conn->db->max_data - 1] = '\0';
}

void Database_get(struct Connection *conn, int id)
{
    if (!conn || !conn->db) die(conn, "No connection for get");
    if (id < 0 || id >= conn->db->max_rows) die(conn, "ID out of range");

    struct Address *addr = &conn->db->rows[id];
    if (addr->set) Address_print(addr);
    else die(conn, "ID is not set");
}

void Database_delete(struct Connection *conn, int id)
{
    if (!conn || !conn->db) die(conn, "No connection for delete");
    if (id < 0 || id >= conn->db->max_rows) die(conn, "ID out of range");

    conn->db->rows[id].set = 0;
    memset(conn->db->rows[id].name, 0, conn->db->max_data);
    memset(conn->db->rows[id].email, 0, conn->db->max_data);
}

/* 列出所有已设置的记录 */
void Database_list(struct Connection *conn)
{
    if (!conn || !conn->db) die(conn, "No connection for list");

    for (int i = 0; i < conn->db->max_rows; i++) {
        struct Address *cur = &conn->db->rows[i];
        if (cur->set) Address_print(cur);
    }
}

void Database_find(struct Connection *conn,const char *pname)
{
    if (!conn || !conn->db) die(conn, "No connection for find");

    for (int i = 0; i < conn->db->max_rows; i++)
    {
        struct Address *cur = &conn->db->rows[i];
        if (strstr(cur->name, pname)) Address_print(cur);
    }
    
}

/* ---- main & CLI ---- */

int main(int argc, char *argv[])
{
    if (argc < 3) die(NULL, "USAGE: ex17 <dbfile> <action> [action params]");

    const char *filename = argv[1];
    char action = argv[2][0];
    struct Connection *conn = NULL;
    int id = 0;

    if (action == 'c') {
        if (argc != 5) die(NULL, "USAGE for create: ex17 <dbfile> c <max_rows> <max_data>");
        int max_rows = atoi(argv[3]);
        int max_data = atoi(argv[4]);
        if (max_rows <= 0 || max_data <= 0) die(NULL, "Invalid max_rows or max_data");

        /* 创建并初始化数据库，然后写入文件并关闭 */
        conn = Database_open(filename, action, max_rows, max_data);
        Database_create(conn);
        Database_write(conn);
        Database_close(conn);
        return 0;
    } else {
        conn = Database_open(filename, action, 0, 0);
    }

    if (argc > 3) id = atoi(argv[3]);
    if (conn->db && id >= conn->db->max_rows) die(conn, "There's not that many records.");

    switch (action) {
        case 'g':
            if (argc != 4) die(conn, "Need an id to get");
            Database_get(conn, id);
            break;
        case 's':
            if (argc != 6) die(conn, "Need id, name, email to set");
            Database_set(conn, id, argv[4], argv[5]);
            Database_write(conn);
            break;
        case 'd':
            if (argc != 4) die(conn, "Need id to delete");
            Database_delete(conn, id);
            Database_write(conn);
            break;
        case 'l':
            if (argc != 3) die(conn, "List takes no extra arguments");
            Database_list(conn);
            break;
        case 'f':
            if (argc != 4) die(conn, "Find requires a name");
            Database_find(conn, argv[3]);
            break;
        default:
            die(conn, "Invalid action, only: c=create, g=get, s=set, d=del, l=list");
    }

    Database_close(conn);
    return 0;
}
