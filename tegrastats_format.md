# Data stream format

- data format
  - 'data:'
    - '{'
    - "ts":timestamp
    - "seq":3
    - "d":{
      - "cpu0_temp_c":54.75
      - "cpu1_temp_c":49.69
      - "gpu_temp_c":null
      - "soc_temp_c":null
      - "tj_temp_c":null
      - "cpu_load_pct":1.2
      - "core0_load_pct":0.0
      - "core1_load_pct":0.0
      - "core2_load_pct":0.0
      - "core3_load_pct":0.0
      - "core4_load_pct":0.0
      - "core5_load_pct":0.0
      - "core6_load_pct":0.0
      - "core7_load_pct":0.0
      - "gpu_load_pct":null
      - "cpu_clk_mhz":null
      - "gpu_clk_mhz":null
      - "emc_clk_mhz":null
      - "pwr_cpu_mw":null
      - "pwr_gpu_mw":null
      - "pwr_soc_mw":null
      - "pwr_total_mw":null
    - '}'
- Example data sample

  ```bash
  data: {"ts":1782717271072,"seq":7,"d":{"cpu0_temp_c":54.75,"cpu1_temp_c":49.69,"gpu_temp_c":null,"soc_temp_c":null,"tj_temp_c":null,"cpu_load_pct":1.2,"core0_load_pct":0.0,"core1_load_pct":0.0,"core2_load_pct":0.0,"core3_load_pct":0.0,"core4_load_pct":0.0,"core5_load_pct":0.0,"core6_load_pct":0.0,"core7_load_pct":0.0,"gpu_load_pct":null,"cpu_clk_mhz":null,"gpu_clk_mhz":null,"emc_clk_mhz":null,"pwr_cpu_mw":null,"pwr_gpu_mw":null,"pwr_soc_mw":null,"pwr_total_mw":null}}
  ```

## feature

- its data stream send via <http://0.0.0.0:8765/telemetry> from Jetson side
- open url <http://192.168.x.x:8765/telemetry>
