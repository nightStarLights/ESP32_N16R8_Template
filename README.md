# ESP32-S3-WROOM-1 (N16R8) 模板工程

基于 **ESP-IDF v6.1** 的最小模板 / 示例工程，目标模组 **ESP32-S3-WROOM-1-N16R8**，
适用官方开发板 [**ESP32-S3-DevKitC-1**](https://docs.espressif.com/projects/esp-idf/zh_CN/v4.4/esp32s3/hw-reference/esp32s3/user-guide-devkitc-1.html) 和 [**Gooouuu ESP32 S3**](https://item.taobao.com/item.htm?_u=n208c7o42qfc0d&id=718248966902&mi_id=0000y8mcoNjzUaPo8kF3kIfwY6WQCPLSp26F0rukXaPDpUg&skuId=5066102752244&spm=a1z09.2.0.0.ab252e8dE05BpB) 核心板。

| 项目 | 参数 |
| --- | --- |
| 芯片 | ESP32-S3（双核 Xtensa LX7，本工程运行在 **240 MHz**） |
| Flash | **16 MB**，Quad（QIO 模式，80 MHz） |
| PSRAM | **8 MB**，Octal（ESP-PSRAM64 / APS6408），80 MHz |
| 控制台 | UART0，TX = GPIO43，RX = GPIO44，**921600** 8N1 |
| 分区表 | 自定义 `partitions.csv`：factory + 双 OTA（各 4 MB）+ 3904 K FAT + 64 K coredump |

> ⚠️ 硬件注意：Octal PSRAM 占用 **GPIO33 ~ GPIO37**（含 DQS），这几个引脚不可再作他用；原生 USB 为 GPIO19/20。

### ESP32-S3-DevKitC-1 引脚图



![ESP32-S3-DevKitC-1 引脚图](https://docs.espressif.com/projects/esp-idf/zh_CN/v4.4/esp32s3/_images/ESP32-S3-DevKitC-1-pin-layout.png)

---

## 1. 配置文件说明

| 文件 | 作用 | 是否入库 |
| --- | --- | --- |
| `sdkconfig` | 构建实际读取的完整配置，由 IDF 生成和维护 | ❌（`.gitignore` 已忽略） |
| `sdkconfig.defaults` | 通用默认值起点（本工程仅作占位，保证下面那个文件能被自动加载） | ✅ |
| `sdkconfig.defaults.esp32s3` | **本工程所有"非默认"配置项**（真正需要版本管理的配置） | ✅ |

### 加载规则（ESP-IDF 6.1 实测）

1. 构建时依次加载 `sdkconfig.defaults` → `sdkconfig.defaults.<target>`（本工程即 `.esp32s3`）；
2. **只有 `sdkconfig.defaults` 存在时，才会继续加载 `sdkconfig.defaults.esp32s3`**（这是 IDF 的行为，缺前者则后者被静默忽略）；
3. `sdkconfig` 中已显式写入的值优先级最高，defaults 不会覆盖它；
4. 想验证 defaults 是否真的被加载，可以看 `build/build.ninja` 里 kconfgen 命令行是否带 `--defaults` 参数。

### 修改配置的标准流程

```bash
idf.py menuconfig        # 修改配置并保存（写入 sdkconfig）
idf.py save-defconfig    # 导出"与 IDF 默认值不同"的项
# 注意：save-defconfig 的输出路径固定为 sdkconfig.defaults，不支持 -o 参数，
#       导出后请把内容同步进 sdkconfig.defaults.esp32s3（保持 sdkconfig.defaults 只留注释）。
```

---

## 2. 当前生效配置一览（sdkconfig）

### 2.1 系统与性能

| 配置项 | 当前值 | IDF 默认 | 说明 |
| --- | --- | --- | --- |
| `ESP_DEFAULT_CPU_FREQ_MHZ` | **240** | 160 | 提频 50%，配合 `-O2` 性能优化 |
| `COMPILER_OPTIMIZATION_PERF` | y | SIZE | 应用按性能优化编译 |
| `ESP32S3_INSTRUCTION_CACHE` | **32 KB** | 16 KB | 指令缓存翻倍（占用 16 KB SRAM） |
| `ESP32S3_DATA_CACHE` | **64 KB** | 32 KB | 带 PSRAM 时收益明显（占用 32 KB SRAM） |
| `ESP_MAIN_TASK_STACK_SIZE` | **8192** | 3584 | 便于在 `app_main` 中初始化 WiFi/BT/HTTPS |
| `FREERTOS_HZ` | **1000** | 100 | 调度精度 1 ms（默认 10 ms）；功耗略增 |
| `ESP_INT_WDT` / `ESP_TASK_WDT` | 开 | 开 | 看门狗保护 |

### 2.2 Flash 与启动

| 配置项 | 当前值 | IDF 默认 | 说明 |
| --- | --- | --- | --- |
| `ESPTOOLPY_FLASHMODE_QIO` | y | DIO | Quad flash 四线读取 |
| `ESPTOOLPY_FLASHSIZE_16MB` | y | 2 MB | 模组实际容量 |
| `ESPTOOLPY_FLASHFREQ_80M` | 80 MHz | 80 MHz | 120 MHz 需实测（HPM 已默认开启） |
| `BOOTLOADER_COMPILER_OPTIMIZATION_PERF` | y | SIZE | 加快启动 |
| `PARTITION_TABLE_CUSTOM` | y | 单一 factory | 使用 `partitions.csv`（默认文件名即匹配） |

### 2.3 PSRAM（8 MB Octal）

| 配置项 | 当前值 | IDF 默认 | 说明 |
| --- | --- | --- | --- |
| `SPIRAM` | y | 关 | 启用外部 RAM |
| `SPIRAM_MODE_OCT` | y | QUAD | N16R8 为 Octal PSRAM |
| `SPIRAM_TYPE_ESPPSRAM64` | y | AUTO | 8 MB = 64 Mbit |
| `SPIRAM_SPEED_80M` | y | 40 MHz | **不要选 120 MHz**：Octal 120 M 是实验特性，官方明确警告温度变化约 ±20 ℃ 会随机崩溃 |
| `SPIRAM_TRY_ALLOCATE_WIFI_LWIP` | y | n | WiFi/LWIP 缓冲优先放 PSRAM，省 30~60 KB 内部 RAM |
| `SPIRAM_MALLOC_ALWAYSINTERNAL` | 16384 | 16384 | ≤16 KB 的分配优先用内部 RAM |
| `SPIRAM_MALLOC_RESERVE_INTERNAL` | 32768 | 32768 | 内部 DMA 预留池；若同时重度使用 WiFi + BLE 且出现分配失败，可提到 65536 |
| `SPIRAM_MEMTEST` | y | y | 启动自检；追求启动速度可关闭 |

### 2.4 Wi-Fi

| 配置项 | 当前值 | 说明 |
| --- | --- | --- |
| `ESP_WIFI_ENABLED` | y | S3 默认开启 |
| `ESP_WIFI_STATIC_RX_BUFFER_NUM` | 16 | 因启用 `SPIRAM_TRY_ALLOCATE_WIFI_LWIP`，IDF 推荐的默认/最小值 |
| `ESP_WIFI_RX_BA_WIN` | 16 | 同上；若小于 16 会明显影响吞吐与兼容性 |
| `ESP_WIFI_TX_BUFFER` | Static（16 个） | 开启 `TRY_ALLOCATE_WIFI_LWIP` 后 IDF 强制静态 TX 缓冲 |
| `ESP_WIFI_CACHE_TX_BUFFER_NUM` | 32 | 随 PSRAM 分配策略引入 |
| `ESP_WIFI_AMPDU_RX/TX_ENABLED` | y / y | 吞吐优化 |
| `ESP_WIFI_TASK_PINNED_TO_CORE_0` | y | WiFi 任务固定在 Core0 |

### 2.5 蓝牙（NimBLE）

| 配置项 | 当前值 | 说明 |
| --- | --- | --- |
| `BT_ENABLED` + `BT_NIMBLE_ENABLED` | y | 使用 NimBLE 协议栈（比 Bluedroid 省 flash/RAM；S3 无经典蓝牙） |
| `BT_CTRL_BLE_MAX_ACT` | 2 | 控制器最大活动实例，每个约 828 B。注意：**广播、扫描、连接各占一个实例**，若需"1 连接 + 持续广播 + 扫描"应改为 3 |
| `BT_NIMBLE_MAX_CONNECTIONS` | 3 | 主机侧上限，与控制器上限（2）不一致，按需对齐 |
| `BT_NIMBLE_ROLE_*` | 全部开启 | 只保留实际使用的角色可省 flash/RAM |
| `BT_NIMBLE_LOG_LEVEL` | INFO | 量产可降到 WARNING/NONE |
| `ESP_COEX_SW_COEXIST_ENABLE` | y | WiFi/BT 软件共存（两者同时用必须保持开启） |

### 2.6 HTTPS 服务器

| 配置项 | 当前值 | 说明 |
| --- | --- | --- |
| `ESP_HTTPS_SERVER_ENABLE` | y | 启用 TLS HTTP 服务 |
| `ESP_HTTPS_SERVER_CERT_SELECT_HOOK` | y | 按 SNI 动态选证书；若不需要多证书可关闭 |

### 2.7 控制台与调试

| 配置项 | 当前值 | 说明 |
| --- | --- | --- |
| `ESP_CONSOLE_UART_CUSTOM` | y | 串口控制台（UART0；TX/RX 使用 S3 默认 43/44） |
| `ESP_CONSOLE_UART_BAUDRATE` | **921600** | 应用日志波特率 |
| `ESPTOOLPY_MONITOR_BAUD` | **921600** | `idf.py monitor` 自动使用该波特率 |
| `ESP_COREDUMP_ENABLE_TO_FLASH` | y | 崩溃现场写入 flash coredump 分区（见第 5 节） |
| `LOG_DEFAULT_LEVEL` | INFO | 如需精简可改 WARN |
| `IDF_EXPERIMENTAL_FEATURES` | y | 仅让实验选项可见；当前未使用任何依赖项，可关闭 |

---

## 3. 分区表（partitions.csv）

| 名称 | 类型 | 子类型 | 偏移 | 大小 | 说明 |
| --- | --- | --- | --- | --- | --- |
| nvs | data | nvs | 0x9000 | 24 K | WiFi/BT 校准与应用数据 |
| otadata | data | ota | 0xF000 | 8 K | OTA 状态 |
| phy_init | data | phy | 0x11000 | 4 K | PHY 校准 |
| factory | app | factory | 0x20000 | 4 M | 出厂固件（首次上电启动；不参与 OTA 轮换，见 3.2） |
| ota_0 | app | ota_0 | 0x420000 | 4 M | OTA 槽 A（与 B 交替升级） |
| ota_1 | app | ota_1 | 0x820000 | 4 M | OTA 槽 B |
| storage | data | fat | 0xC20000 | 3904 K | 字体/图片等资源 |
| coredump | data | coredump | 0xFF0000 | 64 K | panic 现场快照（第 5 节） |

- 全部偏移写死，64 K / 4 K 对齐，精确铺满 16 MB（已核对：`0xC20000 + 3904K + 64K = 0x1000000`）。
- 分区表偏移 `0x8000`（默认），当前 bootloader 约 30 KB 以内；**若将来开启 Secure Boot / Flash 加密，bootloader 会变大，需要改 `PARTITION_TABLE_OFFSET=0x9000` 并同步调整本表**。
- coredump 大小可估算为 `20 + 任务数 × (12 + TCB + 最大任务栈)` 字节；任务多/栈大时可继续从 storage 切到 128 K / 256 K。
- 本工程**保留 factory**（不删除），原因、取舍和后续可选的布局方案见 3.2 节。
- ⚠️ 分区表已调整过（新增 coredump、storage 缩小），**首次使用需重新烧录分区表**（`idf.py flash` 会一并写入）；storage 边界变化后建议重新格式化，见 3.1 节。

### 3.1 格式化 storage（FAT）分区

**什么时候需要**：首次使用该分区、分区表调整（大小/位置变化）后、文件系统损坏挂载失败时。

**关键概念**：storage 分区上运行的是「wear leveling (WL) + FATFS」（由 `esp_vfs_fat_spiflash_mount_rw_wl()` 挂载），
文件系统结构必须由**设备端 FATFS 或 IDF 的打包工具**创建，主机上的普通格式化工具无法直接使用。

**方式 A：构建时生成 FATFS 镜像并烧录（推荐，零运行时代码）**

fatfs 组件提供了 CMake 函数，可在构建时把主机目录打包成与分区匹配的 WL-FAT 镜像，并随 `idf.py flash` 一起烧录。
在 `main/CMakeLists.txt` 中加入：

```cmake
# 用 main/fatfs_image/ 目录内容生成支持磨损均衡的 FATFS 镜像，
# 并在 idf.py flash 时自动写入 storage 分区
fatfs_create_spiflash_image(storage "${CMAKE_CURRENT_LIST_DIR}/fatfs_image" FLASH_IN_PROJECT PRESERVE_TIME)
```

- 新建 `main/fatfs_image/` 目录，放入初始资源（字体/图片等，空目录可先放一个占位文件）；
- 构建后生成 `build/storage.bin`，`idf.py -p PORT flash` 会自动将其烧入 storage 分区；
- 生成的镜像支持磨损均衡，设备端用 `esp_vfs_fat_spiflash_mount_rw_wl()` 即可直接挂载。

**方式 B：运行时自动格式化（首次挂载时建立文件系统）**

```c
#include "esp_vfs_fat.h"

static wl_handle_t s_wl_handle = WL_INVALID_HANDLE;

const esp_vfs_fat_mount_config_t mount_config = {
    .max_files = 5,                     // 最多同时打开的文件数
    .format_if_mount_failed = true,     // 关键：挂载失败时自动格式化
    .allocation_unit_size = CONFIG_WL_SECTOR_SIZE,
    .use_one_fat = false,
};
ESP_ERROR_CHECK(esp_vfs_fat_spiflash_mount_rw_wl("/fat", "storage", &mount_config, &s_wl_handle));
```

只想主动清空/重建文件系统（挂载状态无关，均可调用）：

```c
esp_vfs_fat_spiflash_format_rw_wl("/fat", "storage");
```

**方式 C：命令行擦除 + 下次启动自动格式化**

擦除只是把分区写成 0xFF（**不等于格式化**），需要配合方式 B 的 `format_if_mount_failed = true`，
设备下次启动挂载失败时会自动建立文件系统：

```bash
# esptool 按区域擦除（地址/大小取自 partitions.csv：0xC20000 / 3904K = 0x3D0000）
python -m esptool -c esp32s3 -p /dev/ttyUSB0 erase-region 0xc20000 0x3d0000

# 或 parttool 按分区名擦除（自动读取设备上的分区表，推荐）
python $IDF_PATH/components/partition_table/parttool.py -p /dev/ttyUSB0 erase_partition --partition-name=storage
```

> 常用辅助命令：查看分区偏移/大小
> `python $IDF_PATH/components/partition_table/parttool.py -p /dev/ttyUSB0 get_partition_info --partition-name=storage --info offset`

**选择建议**：模板/量产固件推荐「方式 A」（出厂即带文件系统）；调试阶段用「方式 B」省事；只想快速清空用「方式 C」。

### 3.2 OTA 分区说明（factory + A/B 双槽）

**当前布局保持不变**：`factory(4 M) + ota_0(4 M) + ota_1(4 M) + otadata(8 K)`。
删除 factory 可以省出 4 MB，但本工程**暂不删除**，保留"出厂保底版本"，等实际项目需要 OTA 时再评估（取舍见本节末尾）。

**为什么要两个 ota 槽（A/B）**

OTA 升级不能覆盖正在运行的固件，两个槽轮流当"运行区/接收区"：

```
运行 ota_0 → 新固件写入 ota_1 → 切 otadata → 重启后运行 ota_1
下次升级   → 新固件写回 ota_0 → 切 otadata → 重启后运行 ota_0 （如此交替）
```

好处：升级过程中掉电/断网只等于"升级失败"，正在运行的固件始终完整；配合回滚还能自动恢复。

**factory 的定位**

| 角色 | 说明 |
| --- | --- |
| 默认启动分区 | otadata 为空白（首次上电）时启动 factory |
| 串口烧录目标 | `idf.py flash` 默认把 app 烧进 factory，并烧写 `ota_data_initial.bin` 重置 OTA 状态 |
| 出厂保底版本 | **不参与 OTA 轮换**（`esp_ota_get_next_update_partition()` 只在 ota_0 ~ ota_15 之间循环），必要时可用 `esp_ota_set_boot_partition()` 手动切回 |

**升级流程（关键 API）**

```c
const esp_partition_t *update = esp_ota_get_next_update_partition(NULL);  // 从 ota_0 运行时返回 ota_1
esp_ota_begin(update, OTA_SIZE_UNKNOWN, &handle);
esp_ota_write(handle, data, len);
esp_ota_end(handle);
esp_ota_set_boot_partition(update);   // 切 otadata —— 不调用则重启后仍启动原分区
esp_restart();                        // 重启后 bootloader 按 otadata 启动新槽
```

用 `esp_https_ota()` 时，切分区与重启由内部处理。

**失败回滚（需先开启 `CONFIG_BOOTLOADER_APP_ROLLBACK_ENABLE=y`，当前未开）**

1. 新固件首次启动 → 状态 `PENDING_VERIFY`（试用期）；
2. 应用自检通过 → `esp_ota_mark_app_valid_cancel_rollback()` → 标记 `VALID`，升级完成；
3. 应用自检失败 → `esp_ota_mark_app_invalid_rollback_and_reboot()` → 立即回滚；
4. 崩溃 / 看门狗 / 掉电（来不及标记）→ 下次启动时 bootloader 把该槽标记为 `ABORTED` 并跳过 → **自动回滚到上一个有效槽**。

> ⚠️ 试用期内**任何一次重启**（包括手动按复位）都会被判定为失败回滚——自检通过后要尽早调用 `mark_valid`。
> 三种"失败"的区别：写入阶段失败 → otadata 未改动，重启仍启动原槽（天然安全）；写入成功但新固件崩溃 → 未开回滚会一直崩溃循环，开启后自动回退。

**以后若要调整布局（仅供参考，本工程暂不改动）**

- **删 factory**：省 4 MB 给 storage；启动/烧录目标自动落到 ota_0（bootloader 行为），OTA 能力不变（仍为双槽），损失是"出厂保底版本"这条退路；
- **完全不用 OTA**：只留一个 app 分区 + 扩大 storage，但以后加 OTA 需重做分区表。

---

## 4. 变更记录（相对 IDF 默认值）

### 4.1 已入库：`sdkconfig.defaults.esp32s3` 中记录的项

**目标与构建**

- `CONFIG_IDF_TARGET="esp32s3"`
- `CONFIG_BOOTLOADER_COMPILER_OPTIMIZATION_PERF=y`（默认 SIZE，加快启动）
- `CONFIG_COMPILER_OPTIMIZATION_PERF=y`（默认 SIZE）

**Flash 与分区表**

- `CONFIG_ESPTOOLPY_FLASHMODE_QIO=y`（默认 DIO）
- `CONFIG_ESPTOOLPY_FLASHSIZE_16MB=y`（默认 2 MB）
- `CONFIG_PARTITION_TABLE_CUSTOM=y`

**系统 / 性能 / 内存**

- `CONFIG_ESP_DEFAULT_CPU_FREQ_MHZ_240=y`（默认 160 MHz）
- `CONFIG_ESP32S3_INSTRUCTION_CACHE_32KB=y`（默认 16 KB，SRAM heap −16 KB）
- `CONFIG_ESP32S3_DATA_CACHE_64KB=y`（默认 32 KB，SRAM heap −32 KB）
- `CONFIG_ESP_MAIN_TASK_STACK_SIZE=8192`（默认 3584）
- `CONFIG_FREERTOS_HZ=1000`（默认 100）
- `CONFIG_ESP_CONSOLE_UART_CUSTOM=y` + `CONFIG_ESP_CONSOLE_UART_BAUDRATE=921600`（默认 115200；串口号/引脚沿用 S3 默认：UART0 / GPIO43 / GPIO44）

**PSRAM**

- `CONFIG_SPIRAM=y` / `CONFIG_SPIRAM_MODE_OCT=y` / `CONFIG_SPIRAM_TYPE_ESPPSRAM64=y` / `CONFIG_SPIRAM_SPEED_80M=y`
- `CONFIG_SPIRAM_TRY_ALLOCATE_WIFI_LWIP=y`（WiFi/LWIP 缓冲进 PSRAM，省 30~60 KB 内部 RAM）

**蓝牙（NimBLE）**

- `CONFIG_BT_ENABLED=y` / `CONFIG_BT_NIMBLE_ENABLED=y`（默认关闭蓝牙）
- `CONFIG_BT_CTRL_BLE_MAX_ACT=2`（默认 6，省 RAM）

**HTTPS 服务器**

- `CONFIG_ESP_HTTPS_SERVER_ENABLE=y` / `CONFIG_ESP_HTTPS_SERVER_CERT_SELECT_HOOK=y`

**调试**

- `CONFIG_ESP_COREDUMP_ENABLE_TO_FLASH=y`（配合 `partitions.csv` 中的 coredump 分区）
- `CONFIG_IDF_EXPERIMENTAL_FEATURES=y`（如无实验特性需求可移除）

> WiFi 的 `STATIC_RX_BUFFER_NUM=16`、`RX_BA_WIN=16`、静态 TX 缓冲等，
> 都是 `SPIRAM_TRY_ALLOCATE_WIFI_LWIP=y` 的**连带默认值**，会自动跟随，无需单独记录。

### 4.2 同步状态

✅ 当前 `sdkconfig` 中所有非默认项均已记录到 `sdkconfig.defaults.esp32s3`，
删除 `sdkconfig` 后重新构建可完整复现（另需保留 `sdkconfig.defaults` 占位文件，见第 1 节）。

### 4.3 建议但尚未启用（可选清单）

| 建议 | 配置项 | 取舍 |
| --- | --- | --- |
| NimBLE 日志降级 | `BT_NIMBLE_LOG_LEVEL_WARNING=y` | 减少日志噪音与固件体积 |
| 裁剪 BLE 角色 | 关闭 `BT_NIMBLE_ROLE_CENTRAL/OBSERVER` | 仅做从机时可省 flash/RAM |
| 连接数与控制器对齐 | `BT_NIMBLE_MAX_CONNECTIONS=2` | 与 `BT_CTRL_BLE_MAX_ACT=2` 一致 |
| 启用 OTA 回滚 | `BOOTLOADER_APP_ROLLBACK_ENABLE=y` | 做 OTA 升级功能时建议开启，配合 mark_valid API（见 3.2 节） |
| 加快启动 | 关闭 `SPIRAM_MEMTEST` | 放弃启动期 PSRAM 自检 |
| 抓取更完整的崩溃现场 | `ESP_COREDUMP_CAPTURE_DRAM=y` | 需把 coredump 分区扩到 ≥128 K |
| 保留首次崩溃现场 | `ESP_COREDUMP_FLASH_NO_OVERWRITE=y` | 多次崩溃时只保留第一次 |
| 省内部 RAM（进阶） | `SPIRAM_ALLOW_BSS_SEG_EXTERNAL_MEMORY=y` | WiFi/BT 的 .bss 放入 PSRAM |
| 省 IRAM（进阶） | `SPIRAM_XIP_FROM_PSRAM=y` | flash 代码/只读数据搬到 PSRAM，启动变慢 |
| Flash 提速 | `ESPTOOLPY_FLASHFREQ_120M` | 需 flash 芯片支持，建议实测稳定性 |

---

## 5. Core Dump：定位死机现场（已启用）

> 本模板（示例工程）已启用：
> - `partitions.csv` 预留 64 K `coredump` 分区（见第 3 节）；
> - `CONFIG_ESP_COREDUMP_ENABLE_TO_FLASH=y`（自动搭配 ELF 格式 + SHA256 校验）。

### 能干什么

程序 panic（`abort()`、空指针、看门狗、非法指令等）时，把**现场快照**写入独立 flash 分区：

- 崩溃任务的寄存器、调用栈（backtrace）；
- 各任务（按优先级）的 TCB 与栈的副本；
- panic 原因、内存区域内容。

重启后快照仍在，可在主机上反复分析——比串口 panic 日志可靠得多（日志刷屏/断电即失），适合偶发崩溃、无人值守设备。

### 怎么用

1. 正常构建烧录并运行：

   ```bash
   idf.py -p /dev/ttyUSB0 flash monitor
   ```

2. 触发一次崩溃（调试时可写个 `assert(0);`，实际项目中等偶发问题复现）。

3. 在主机上解析（**不要**先重新编译烧录，否则符号会对不上）：

   ```bash
   idf.py coredump-info  -p /dev/ttyUSB0    # 打印崩溃任务寄存器、调用栈、任务列表
   idf.py coredump-debug -p /dev/ttyUSB0    # 用 GDB 打开（bt / info threads / p <变量>）
   ```

   也可以把 dump 保存成文件后离线分析：`idf.py coredump-info -c <文件>`。
   更多参数：`idf.py coredump-info --help`；独立工具：`esp-coredump`。

### 注意事项

- 解析需要**与固件匹配的 ELF**（`build/` 下的 .elf）。重新编译并烧录后，旧 dump 的符号可能对不上；
- 若开启了「任务栈放入 PSRAM」（`FREERTOS_TASK_CREATE_ALLOW_EXT_MEM`），Flash core dump **不可用**；
- 开启 Flash 加密时，分区声明需要加 `encrypted` 标志，且不能直接用 `idf.py` 读取（需从设备读取解密）；
- 每次崩溃默认覆盖上一次的 dump（可开 `CONFIG_ESP_COREDUMP_FLASH_NO_OVERWRITE=y` 保留第一次）；
- 如临时不想用，可切到 UART 模式 `CONFIG_ESP_COREDUMP_ENABLE_TO_UART=y`（monitor 自动解码），或 `CONFIG_ESP_COREDUMP_ENABLE_TO_NONE=y` 关闭。

---

## 6. 常用命令

```bash
# 构建 / 烧录 / 监视（波特率 921600 已写入配置）
idf.py build
idf.py -p /dev/ttyUSB0 flash monitor        # 端口按实际情况修改

# 配置
idf.py menuconfig                            # 图形化配置
idf.py save-defconfig                        # 导出非默认项到 sdkconfig.defaults
idf.py reconfigure                           # 仅重新解析配置

# 分区表 / Core Dump
idf.py partition-table                       # 生成并打印分区表
idf.py partition-table-flash                 # 仅烧录分区表
idf.py coredump-info  -p /dev/ttyUSB0        # 解析崩溃现场

# storage（FAT）分区维护（详见 3.1 节）
python -m esptool -c esp32s3 -p /dev/ttyUSB0 erase-region 0xc20000 0x3d0000        # 按区域擦除
python $IDF_PATH/components/partition_table/parttool.py -p /dev/ttyUSB0 erase_partition --partition-name=storage   # 按分区名擦除

# 干净重建（所有非默认项均在 defaults 中，可完整复现）
rm -rf build sdkconfig && idf.py build
```

---

## 7. 参考资料

- ESP32-S3-DevKitC-1 用户指南：<https://docs.espressif.com/projects/esp-idf/zh_CN/v4.4/esp32s3/hw-reference/esp32s3/user-guide-devkitc-1.html>
- ESP32-S3-DevKitC-1 引脚图：<https://docs.espressif.com/projects/esp-idf/zh_CN/v4.4/esp32s3/_images/ESP32-S3-DevKitC-1-pin-layout.png>
- ESP-IDF 外部 RAM 配置：`docs/en/api-guides/external-ram.rst`
- Core Dump：`docs/en/api-guides/core_dump.rst`
- ESP32-S3-WROOM-1 数据手册（引脚复用与 PSRAM 占用引脚：GPIO33~37）
