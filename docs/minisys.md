# Minisys 使用指南

## 构建和下载

目标器件为 **Artix-7 `xc7a100tfgg484-1`**，板载时钟 100 MHz。每次为一套电路选定一个顶层，约束文件名与该顶层同名。若使用其他开发板，请按其器件封装、IO 电平、时钟和数码管极性调整约束与驱动。

1. 打开 Vivado 命令行环境，进入仓库根目录。
2. 用目标顶层替换命令中的 `uart_hex_monitor`，运行完整的综合、布局布线与比特流生成。

   ```sh
   vivado -mode batch -source scripts/build_minisys.tcl -tclargs uart_hex_monitor
   ```

3. 在 `build/vivado/<top>/` 查看 `timing.rpt` 和 `utilization.rpt`。需要指定输出目录时，在顶层名后加一个目录参数。
4. 将板卡通过数据线连接到电脑。在 Vivado Hardware Manager 中连接目标，选择 **Program Device**，加载生成的 `<top>.bit`。时序示例下载后先按一次复位键。

使用图形界面时，创建 RTL 工程并选择同一器件，把 `rtl/` 下的 `.v` 加为 Design Sources，设置目标模块为顶层，只导入其对应的 [XDC](../constraints/minisys/)。仿真文件可从 [`sim/`](../sim/) 加为 Simulation Sources。

## 板上操作

| 顶层 | 输入和观察点 |
| --- | --- |
| `add_sub_mux` | 用拨码输入两组 4 位数、使能和加减选择，查看低四位 LED。 |
| `dff` | 用 S1 清零，用拨码改变使能和数据，在 LED0 上观察 Q。 |
| `reg8file` | 用 S1 清零。先固定写地址和数据，再打开写使能。关掉写使能后切换读地址，在八位 LED 上观察结果。 |
| `led_chaser` | S1 复位，S2 翻转启停。两位拨码控制速度，另一个拨码控制方向。 |
| `display_demo` | S1 复位，S2 暂停或继续定时计数，S3 更新两个按键计数，SW0 向上显示。 |
| `uart_beacon` | S1 复位后，电脑周期收到 `HELLO FPGA`。 |
| `uart_hex_monitor` | 用 S1 清除显示。电脑发送十六进制文本，按 S3 触发回发 `READY`。 |
| `uart_keyword_console` | 用 S1 复位。发送 `start`、`stop`、`fpga` 等文本并附加行尾，查看单字节回复。 |

时钟位于 `Y18`，S1、S2、S3 分别对应 `R1`、`P1`、`P5`。串口从 FPGA 的视角定义，`V18` 是 TX，`Y19` 是 RX。完整端口和管脚对应以各设计的 XDC 为准。

打开板载 USB-UART 对应的串口，选择 **9600、8N1、无流控**。发送显示内容时使用 ASCII 文本模式，例如输入 `A` 发送字节 `0x41`。关键词示例需用 CR、LF 或 CRLF 作为行结束符。
