# ===================================================================================
# Definisanje direktorijuma u kojem ce biti projekat
# vivado terminal : source ./<putanja>
# ===================================================================================
cd ..
set root_dir [pwd]
cd scripts
set resultDir ../vivado_project

file mkdir $resultDir

create_project RISCV_CPU $resultDir -part xc7z020clg400-1
set_property board_part digilentinc.com:zybo-z7-10:part0:1.2 [current_project]

# ===================================================================================
# Ukljucivanje svih izvornih i simulacionih fajlova u projekat
# ===================================================================================
add_files -norecurse ../hdl/adder.sv
add_files -norecurse ../hdl/alu.sv
add_files -norecurse ../hdl/aludec.sv
add_files -norecurse ../hdl/dmem.sv
add_files -norecurse ../hdl/extend.sv
add_files -norecurse ../hdl/hazard_unit.sv
add_files -norecurse ../hdl/imem.sv
add_files -norecurse ../hdl/maindec.sv
add_files -norecurse ../hdl/regfile.sv
add_files -norecurse ../hdl/L1_cache.sv
add_files -norecurse ../hdl/L2_cache.sv
add_files -norecurse ../hdl/cache_subsystem.sv
add_files -norecurse ../hdl/controller.sv
add_files -norecurse ../hdl/datapath.sv
add_files -norecurse ../hdl/riscVpipeline.sv
add_files -norecurse ../hdl/TOP.sv


update_compile_order -fileset sources_1


set_property SOURCE_SET sources_1 [get_filesets sim_1]
set_property -name {STEPS.SYNTH_DESIGN.ARGS.MORE OPTIONS} -value {-mode out_of_context} -objects [get_runs synth_1]

add_files -fileset sim_1 -norecurse ../tb/pipeline_tb.sv
#add_files -fileset sim_1 -norecurse ../tb/cache_L1_tb.sv
#add_files -fileset sim_1 -norecurse ../tb/cache_L2_tb.sv
#add_files -fileset sim_1 -norecurse ../tb/cache_subsystem_tb.sv

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1