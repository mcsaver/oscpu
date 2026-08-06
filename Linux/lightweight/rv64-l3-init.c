// SPDX-License-Identifier: MIT
// libc-free PID1 for the local RV64 L3 lightweight-Linux signoff layer.
// Syscall numbers and the RISC-V a7/a0-a5 ABI come from Linux 6.6 nolibc/UAPI.

#include <nolibc.h>
#include <asm/ioctls.h>
#include <asm/termbits.h>

#define L3_BEGIN "__RV64_L3_PID1_BEGIN__\n"
#define L3_MOUNTS "__RV64_L3_MOUNTS_PASS__\n"
#define L3_FILES "__RV64_L3_FILES_PASS__\n"
#define L3_CASE_SELECT "__RV64_L3_CASE_SELECT__\n"
#define L3_CASE_BOOT "__RV64_L3_CASE_BOOT__\n"
#define L3_CASE_MMU "__RV64_L3_CASE_MMU__\n"
#define L3_CASE_PROCESS "__RV64_L3_CASE_PROCESS__\n"
#define L3_CASE_TIMER "__RV64_L3_CASE_TIMER__\n"
#define L3_CASE_STORAGE "__RV64_L3_CASE_STORAGE__\n"
#define L3_CASE_ATOMIC "__RV64_L3_CASE_ATOMIC__\n"
#define L3_CASE_INTERRUPT "__RV64_L3_CASE_INTERRUPT__\n"
#define L3_CASE_SHUTDOWN "__RV64_L3_CASE_SHUTDOWN__\n"
#define L3_CASE_ALL "__RV64_L3_CASE_ALL__\n"
#define L3_BOOT "__RV64_L3_BOOT_PASS__\n"
#define L3_COW "__RV64_L3_COW_PASS__\n"
#define L3_PROCESS "__RV64_L3_PROCESS_PASS__\n"
#define L3_TIME "__RV64_L3_TIME_PASS__\n"
#define L3_TMPFS "__RV64_L3_TMPFS_PASS__\n"
#define L3_ATOMIC "__RV64_L3_ATOMIC_PASS__\n"
#define L3_UART_ARM1 "__RV64_L3_UART_ARM_1__\n"
#define L3_UART_RX1 "__RV64_L3_UART_RX_1=0x41__\n"
#define L3_UART_ARM2 "__RV64_L3_UART_ARM_2__\n"
#define L3_UART_RX2 "__RV64_L3_UART_RX_2=0x42__\n"
#define L3_UART_IRQ "__RV64_L3_UART_IRQ_PASS__\n"
#define L3_SHUTDOWN_ARM "__RV64_L3_SHUTDOWN_ARM__\n"
#define L3_PASS "__RV64_L3_LIGHTWEIGHT_PASS__\n"

enum l3_case {
	CASE_BOOT = 'b',
	CASE_MMU = 'm',
	CASE_PROCESS = 'p',
	CASE_TIMER = 't',
	CASE_STORAGE = 's',
	CASE_ATOMIC = 'a',
	CASE_INTERRUPT = 'i',
	CASE_SHUTDOWN = 'd',
	CASE_ALL = 'x',
};

static long raw_write(int fd, const void *buf, unsigned long len)
{
	return my_syscall3(__NR_write, fd, buf, len);
}

static void write_all(int fd, const char *buf, unsigned long len)
{
	while (len) {
		long done = raw_write(fd, buf, len);
		if (done <= 0)
			return;
		buf += done;
		len -= (unsigned long)done;
	}
}

static void emit(const char *text)
{
	write_all(1, text, strlen(text));
}

static void emit_signed(long value)
{
	char buf[32];
	unsigned long magnitude;
	unsigned int pos = sizeof(buf);

	if (value < 0) {
		emit("-");
		magnitude = (unsigned long)(-(value + 1)) + 1;
	} else {
		magnitude = (unsigned long)value;
	}
	do {
		buf[--pos] = (char)('0' + magnitude % 10);
		magnitude /= 10;
	} while (magnitude);
	write_all(1, buf + pos, sizeof(buf) - pos);
}

static __attribute__((noreturn)) void poweroff_now(void)
{
	(void)my_syscall0(__NR_sync);
	(void)my_syscall4(__NR_reboot, LINUX_REBOOT_MAGIC1,
			  LINUX_REBOOT_MAGIC2, LINUX_REBOOT_CMD_POWER_OFF, 0);
	for (;;)
		(void)my_syscall0(__NR_sched_yield);
}

static __attribute__((noreturn)) void fail_stage(const char *stage, long rc)
{
	emit("__RV64_L3_FAIL__ stage=");
	emit(stage);
	emit(" rc=");
	emit_signed(rc);
	emit("\n");
	poweroff_now();
}

static long raw_open(const char *path, int flags, unsigned int mode)
{
	return my_syscall4(__NR_openat, AT_FDCWD, path, flags, mode);
}

static long raw_read(int fd, void *buf, unsigned long len)
{
	return my_syscall3(__NR_read, fd, buf, len);
}

static void raw_close(long fd)
{
	if (fd >= 0)
		(void)my_syscall1(__NR_close, fd);
}

static void make_dir(const char *path)
{
	long rc = my_syscall3(__NR_mkdirat, AT_FDCWD, path, 0755);
	if (rc != 0 && rc != -EEXIST)
		fail_stage("mkdir", rc);
}

static void mount_exact(const char *source, const char *target,
			const char *type, const char *data)
{
	long rc = my_syscall5(__NR_mount, source, target, type, 0, data);
	if (rc != 0)
		fail_stage(target, rc);
}

static long read_path(const char *path, char *buf, unsigned long size)
{
	long fd = raw_open(path, O_RDONLY, 0);
	long total = 0;

	if (fd < 0)
		return fd;
	while ((unsigned long)total + 1 < size) {
		long done = raw_read((int)fd, buf + total,
				     size - (unsigned long)total - 1);
		if (done < 0) {
			raw_close(fd);
			return done;
		}
		if (done == 0)
			break;
		total += done;
	}
	buf[total] = '\0';
	raw_close(fd);
	return total;
}

static int contains_text(const char *haystack, const char *needle)
{
	unsigned long hlen = strlen(haystack);
	unsigned long nlen = strlen(needle);
	unsigned long index;

	if (!nlen || nlen > hlen)
		return 0;
	for (index = 0; index + nlen <= hlen; ++index)
		if (memcmp(haystack + index, needle, nlen) == 0)
			return 1;
	return 0;
}

static void verify_linux_views(void)
{
	char buf[4096];
	long size;
	long tty;

	tty = raw_open("/dev/ttyS0", O_RDWR | O_NOCTTY, 0);
	if (tty < 0)
		fail_stage("dev-ttyS0", tty);
	raw_close(tty);

	size = read_path("/proc/self/status", buf, sizeof(buf));
	if (size <= 0 || !contains_text(buf, "Pid:\t1\n"))
		fail_stage("proc-self-status", size);
	size = read_path("/proc/interrupts", buf, sizeof(buf));
	if (size <= 0)
		fail_stage("proc-interrupts", size);
	size = read_path("/sys/devices/system/cpu/online", buf, sizeof(buf));
	if (size <= 0 || buf[0] != '0')
		fail_stage("sys-cpu-online", size);
}

struct cow_record {
	unsigned int magic;
	unsigned int before;
	unsigned int after;
	unsigned int child_pid;
};

static void verify_cow_clone_wait(void)
{
	long map_value;
	volatile unsigned char *page;
	int pipefd[2];
	long child;
	long waited;
	int status = 0;
	struct cow_record record;

	map_value = my_syscall6(__NR_mmap, 0, 4096, PROT_READ | PROT_WRITE,
				MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
	if (map_value < 0 && map_value >= -4095)
		fail_stage("mmap-private", map_value);
	page = (volatile unsigned char *)map_value;
	page[0] = 0x5a;
	if (my_syscall2(__NR_pipe2, pipefd, 0) != 0)
		fail_stage("pipe2", -1);

	child = my_syscall5(__NR_clone, SIGCHLD, 0, 0, 0, 0);
	if (child < 0)
		fail_stage("clone", child);
	if (child == 0) {
		struct cow_record child_record;
		(void)my_syscall1(__NR_close, pipefd[0]);
		child_record.magic = 0x4c33434fU;
		child_record.before = page[0];
		page[0] = 0xa5;
		child_record.after = page[0];
		child_record.child_pid = (unsigned int)my_syscall0(__NR_getpid);
		if (raw_write(pipefd[1], &child_record, sizeof(child_record)) !=
		    (long)sizeof(child_record))
			my_syscall1(__NR_exit, 91);
		my_syscall1(__NR_exit, 37);
		for (;;)
			;
	}

	(void)my_syscall1(__NR_close, pipefd[1]);
	waited = my_syscall4(__NR_wait4, child, &status, 0, 0);
	if (waited != child || status != (37 << 8))
		fail_stage("wait4-status", status);
	if (raw_read(pipefd[0], &record, sizeof(record)) !=
	    (long)sizeof(record))
		fail_stage("pipe-record", -1);
	raw_close(pipefd[0]);
	if (record.magic != 0x4c33434fU || record.before != 0x5a ||
	    record.after != 0xa5 || record.child_pid != (unsigned int)child ||
	    page[0] != 0x5a)
		fail_stage("cow-parent-child", page[0]);
	(void)my_syscall2(__NR_munmap, (long)page, 4096);
}

static void verify_process_clone_pipe_wait(void)
{
	static const unsigned int child_magic = 0x4c335052U;
	unsigned int observed = 0;
	int pipefd[2];
	int status = 0;
	long child;
	long waited;

	if (my_syscall2(__NR_pipe2, pipefd, 0) != 0)
		fail_stage("process-pipe2", -1);
	child = my_syscall5(__NR_clone, SIGCHLD, 0, 0, 0, 0);
	if (child < 0)
		fail_stage("process-clone", child);
	if (child == 0) {
		(void)my_syscall1(__NR_close, pipefd[0]);
		if (raw_write(pipefd[1], &child_magic, sizeof(child_magic)) !=
		    (long)sizeof(child_magic))
			my_syscall1(__NR_exit, 92);
		my_syscall1(__NR_exit, 23);
		for (;;)
			;
	}
	(void)my_syscall1(__NR_close, pipefd[1]);
	if (raw_read(pipefd[0], &observed, sizeof(observed)) !=
	    (long)sizeof(observed))
		fail_stage("process-pipe-read", -1);
	raw_close(pipefd[0]);
	waited = my_syscall4(__NR_wait4, child, &status, 0, 0);
	if (waited != child || status != (23 << 8) || observed != child_magic)
		fail_stage("process-wait4", status);
}

static unsigned long long timespec_ns(const struct timespec *value)
{
	return (unsigned long long)value->tv_sec * 1000000000ULL +
	       (unsigned long long)value->tv_nsec;
}

static void verify_timers(void)
{
	struct timespec invalid = { .tv_sec = 0, .tv_nsec = 1000000000L };
	struct timespec request = { .tv_sec = 0, .tv_nsec = 1000000L };
	unsigned int round;
	long rc;

	rc = my_syscall4(__NR_clock_nanosleep, CLOCK_MONOTONIC, 0,
			 &invalid, 0);
	if (rc != -EINVAL)
		fail_stage("clock-invalid-nsec", rc);
	for (round = 0; round < 3; ++round) {
		struct timespec before;
		struct timespec after;
		if (my_syscall2(__NR_clock_gettime, CLOCK_MONOTONIC, &before) != 0)
			fail_stage("clock-before", round);
		rc = my_syscall4(__NR_clock_nanosleep, CLOCK_MONOTONIC, 0,
				 &request, 0);
		if (rc != 0)
			fail_stage("clock-sleep", rc);
		if (my_syscall2(__NR_clock_gettime, CLOCK_MONOTONIC, &after) != 0)
			fail_stage("clock-after", round);
		if (timespec_ns(&after) < timespec_ns(&before) +
		    timespec_ns(&request))
			fail_stage("clock-elapsed", round);
	}
}

static void verify_tmpfs_file(void)
{
	static const char payload[] = "rv64-l3-tmpfs";
	char readback[sizeof(payload)];
	long fd = raw_open("/tmp/l3-file", O_CREAT | O_TRUNC | O_RDWR, 0600);

	if (fd < 0)
		fail_stage("tmpfs-open", fd);
	if (raw_write((int)fd, payload, sizeof(payload)) != (long)sizeof(payload))
		fail_stage("tmpfs-write", -1);
	if (my_syscall3(__NR_lseek, fd, 0, SEEK_SET) != 0)
		fail_stage("tmpfs-lseek", -1);
	if (raw_read((int)fd, readback, sizeof(readback)) !=
	    (long)sizeof(readback) || memcmp(readback, payload, sizeof(payload)))
		fail_stage("tmpfs-readback", -1);
	raw_close(fd);
	if (my_syscall3(__NR_unlinkat, AT_FDCWD, "/tmp/l3-file", 0) != 0)
		fail_stage("tmpfs-unlink", -1);
}

static void verify_user_atomics(void)
{
	volatile unsigned long word = 7;
	unsigned long add = 5;
	unsigned long old;
	unsigned long seen;
	unsigned long next;
	unsigned long sc_status;

	__asm__ volatile("amoadd.d %0, %2, (%1)"
			 : "=r"(old)
			 : "r"(&word), "r"(add)
			 : "memory");
	if (old != 7 || word != 12)
		fail_stage("amoadd-d", word);
	word = 11;
	do {
		__asm__ volatile("lr.d %0, (%3)\n"
				 "addi %2, %0, 1\n"
				 "sc.d %1, %2, (%3)"
				 : "=&r"(seen), "=&r"(sc_status), "=&r"(next)
				 : "r"(&word)
				 : "memory");
	} while (sc_status != 0);
	if (seen != 11 || word != 12)
		fail_stage("lrsc-d", word);
}

static long uart_irq_count(void)
{
	char buf[8192];
	long size = read_path("/proc/interrupts", buf, sizeof(buf));
	long line_start = 0;

	if (size <= 0)
		return -1;
	while (line_start < size) {
		long line_end = line_start;
		long colon = -1;
		long index;
		int owner = 0;
		while (line_end < size && buf[line_end] != '\n')
			++line_end;
		for (index = line_start; index < line_end; ++index)
			if (buf[index] == ':') {
				colon = index;
				break;
			}
		if (colon >= 0) {
			long len = line_end - line_start;
			char saved = buf[line_end];
			buf[line_end] = '\0';
			owner = contains_text(buf + line_start, "uart") ||
				contains_text(buf + line_start, "serial") ||
				contains_text(buf + line_start, "ttyS0");
			buf[line_end] = saved;
			if (owner && len > 0) {
				unsigned long count = 0;
				index = colon + 1;
				while (index < line_end &&
				       (buf[index] == ' ' || buf[index] == '\t'))
					++index;
				if (index == line_end || buf[index] < '0' ||
				    buf[index] > '9')
					return -1;
				while (index < line_end && buf[index] >= '0' &&
				       buf[index] <= '9') {
					count = count * 10 + (unsigned long)(buf[index] - '0');
					++index;
				}
				return (long)count;
			}
		}
		line_start = line_end + 1;
	}
	return -1;
}

static void configure_uart_raw(int fd)
{
	struct termios settings;
	long rc = my_syscall3(__NR_ioctl, fd, TCGETS, &settings);
	if (rc != 0)
		fail_stage("uart-tcgets", rc);
	settings.c_iflag = 0;
	settings.c_oflag = 0;
	settings.c_lflag = 0;
	settings.c_cflag &= ~(CSIZE | PARENB);
	settings.c_cflag |= CS8 | CREAD | CLOCAL;
	settings.c_cc[VMIN] = 1;
	settings.c_cc[VTIME] = 0;
	rc = my_syscall3(__NR_ioctl, fd, TCSETS, &settings);
	if (rc != 0)
		fail_stage("uart-tcsets", rc);
}

static enum l3_case select_case(void)
{
	unsigned char selector = 0;
	long fd = raw_open("/dev/ttyS0", O_RDWR | O_NOCTTY, 0);

	if (fd < 0)
		fail_stage("case-uart-open", fd);
	configure_uart_raw((int)fd);
	emit(L3_CASE_SELECT);
	if (raw_read((int)fd, &selector, 1) != 1)
		fail_stage("case-uart-read", selector);
	raw_close(fd);
	switch (selector) {
	case CASE_BOOT:
		emit(L3_CASE_BOOT);
		break;
	case CASE_MMU:
		emit(L3_CASE_MMU);
		break;
	case CASE_PROCESS:
		emit(L3_CASE_PROCESS);
		break;
	case CASE_TIMER:
		emit(L3_CASE_TIMER);
		break;
	case CASE_STORAGE:
		emit(L3_CASE_STORAGE);
		break;
	case CASE_ATOMIC:
		emit(L3_CASE_ATOMIC);
		break;
	case CASE_INTERRUPT:
		emit(L3_CASE_INTERRUPT);
		break;
	case CASE_SHUTDOWN:
		emit(L3_CASE_SHUTDOWN);
		break;
	case CASE_ALL:
		emit(L3_CASE_ALL);
		break;
	default:
		fail_stage("case-selector", selector);
	}
	return (enum l3_case)selector;
}

static void verify_uart_two_rounds(void)
{
	unsigned char byte = 0;
	long irq_before = uart_irq_count();
	long irq_after;
	long fd;

	if (irq_before < 0)
		fail_stage("uart-irq-owner-before", irq_before);
	fd = raw_open("/dev/ttyS0", O_RDWR | O_NOCTTY, 0);
	if (fd < 0)
		fail_stage("uart-open", fd);
	configure_uart_raw((int)fd);
	emit(L3_UART_ARM1);
	if (raw_read((int)fd, &byte, 1) != 1 || byte != 0x41)
		fail_stage("uart-rx-round1", byte);
	emit(L3_UART_RX1);
	emit(L3_UART_ARM2);
	if (raw_read((int)fd, &byte, 1) != 1 || byte != 0x42)
		fail_stage("uart-rx-round2", byte);
	emit(L3_UART_RX2);
	raw_close(fd);
	irq_after = uart_irq_count();
	if (irq_after <= irq_before)
		fail_stage("uart-irq-growth", irq_after - irq_before);
	emit(L3_UART_IRQ);
}

int main(void)
{
	enum l3_case selected;

	emit(L3_BEGIN);
	make_dir("/dev");
	make_dir("/proc");
	make_dir("/sys");
	make_dir("/tmp");
	mount_exact("devtmpfs", "/dev", "devtmpfs", "mode=0755");
	mount_exact("proc", "/proc", "proc", "");
	mount_exact("sysfs", "/sys", "sysfs", "");
	mount_exact("tmpfs", "/tmp", "tmpfs", "mode=0755,size=4m");
	emit(L3_MOUNTS);
	verify_linux_views();
	emit(L3_FILES);
	selected = select_case();
	if (selected == CASE_BOOT || selected == CASE_ALL)
		emit(L3_BOOT);
	if (selected == CASE_MMU || selected == CASE_ALL) {
		verify_cow_clone_wait();
		emit(L3_COW);
	}
	if (selected == CASE_PROCESS || selected == CASE_ALL) {
		verify_process_clone_pipe_wait();
		emit(L3_PROCESS);
	}
	if (selected == CASE_TIMER || selected == CASE_ALL) {
		verify_timers();
		emit(L3_TIME);
	}
	if (selected == CASE_STORAGE || selected == CASE_ALL) {
		verify_tmpfs_file();
		emit(L3_TMPFS);
	}
	if (selected == CASE_ATOMIC || selected == CASE_ALL) {
		verify_user_atomics();
		emit(L3_ATOMIC);
	}
	if (selected == CASE_INTERRUPT || selected == CASE_ALL)
		verify_uart_two_rounds();
	emit(L3_SHUTDOWN_ARM);
	emit(L3_PASS);
	poweroff_now();
}
