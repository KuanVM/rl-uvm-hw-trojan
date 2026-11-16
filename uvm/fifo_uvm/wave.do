onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -expand -group CLOCK /tb_top/clk
add wave -noupdate -expand -group CLOCK /tb_top/dut/clk
add wave -noupdate -expand -group CLOCK /tb_top/dut/sva_inst/clk
add wave -noupdate -expand -group CLOCK /tb_top/vif/clk
add wave -noupdate -expand -group RESET /tb_top/rst_n
add wave -noupdate -expand -group RESET /tb_top/dut/rst_n
add wave -noupdate -expand -group RESET /tb_top/vif/rst_n
add wave -noupdate -expand -group RESET /tb_top/vif/mon_cb/rst_n
add wave -noupdate -expand -group RESET /tb_top/dut/sva_inst/rst_n
add wave -noupdate -expand -group WRITE_ENABLE /tb_top/vif/wr_en
add wave -noupdate -expand -group WRITE_ENABLE /tb_top/dut/wr_en
add wave -noupdate -expand -group WRITE_ENABLE /tb_top/vif/drv_cb/wr_en
add wave -noupdate -expand -group WRITE_ENABLE /tb_top/vif/mon_cb/wr_en
add wave -noupdate -expand -group WRITE_ENABLE /tb_top/dut/sva_inst/wr_en
add wave -noupdate -group DATA_IN /tb_top/dut/data_in
add wave -noupdate -group DATA_IN /tb_top/vif/data_in
add wave -noupdate -group DATA_IN /tb_top/vif/drv_cb/data_in
add wave -noupdate -group DATA_IN /tb_top/vif/mon_cb/data_in
add wave -noupdate -group DATA_IN /tb_top/dut/sva_inst/data_in
add wave -noupdate -expand -group FULL /tb_top/dut/full
add wave -noupdate -expand -group FULL /tb_top/vif/full
add wave -noupdate -expand -group FULL /tb_top/vif/drv_cb/full
add wave -noupdate -expand -group FULL /tb_top/vif/mon_cb/full
add wave -noupdate -expand -group FULL /tb_top/dut/sva_inst/full
add wave -noupdate -group READ_ENABLE /tb_top/dut/rd_en
add wave -noupdate -group READ_ENABLE /tb_top/vif/rd_en
add wave -noupdate -group READ_ENABLE /tb_top/vif/drv_cb/rd_en
add wave -noupdate -group READ_ENABLE /tb_top/vif/mon_cb/rd_en
add wave -noupdate -group READ_ENABLE /tb_top/dut/sva_inst/rd_en
add wave -noupdate -group DATA_OUT /tb_top/dut/data_out
add wave -noupdate -group DATA_OUT /tb_top/vif/data_out
add wave -noupdate -group DATA_OUT /tb_top/vif/drv_cb/data_out
add wave -noupdate -group DATA_OUT /tb_top/vif/mon_cb/data_out
add wave -noupdate -group DATA_OUT /tb_top/dut/sva_inst/data_out
add wave -noupdate -expand -group EMPTY /tb_top/dut/empty
add wave -noupdate -expand -group EMPTY /tb_top/vif/empty
add wave -noupdate -expand -group EMPTY /tb_top/vif/drv_cb/empty
add wave -noupdate -expand -group EMPTY /tb_top/vif/mon_cb/empty
add wave -noupdate -expand -group EMPTY /tb_top/dut/sva_inst/empty
add wave -noupdate -expand -group INTERNAL_STATES /tb_top/dut/wr_ptr
add wave -noupdate -expand -group INTERNAL_STATES /tb_top/dut/sva_inst/wr_ptr
add wave -noupdate -expand -group INTERNAL_STATES /tb_top/dut/rd_ptr
add wave -noupdate -expand -group INTERNAL_STATES /tb_top/dut/sva_inst/rd_ptr
add wave -noupdate -expand -group INTERNAL_STATES /tb_top/dut/count
add wave -noupdate -expand -group INTERNAL_STATES /tb_top/dut/sva_inst/count
add wave -noupdate -group UVM_OTHERS /uvm_pkg::uvm_start_uvm_declarations
add wave -noupdate -group UVM_OTHERS /uvm_pkg::uvm_global_random_seed
add wave -noupdate -group UVM_OTHERS /uvm_pkg::UVM_UNBOUNDED_CONNECTIONS
add wave -noupdate -group UVM_OTHERS /uvm_pkg::uvm_hdl_check_path/uvm_hdl_check_path
add wave -noupdate -group UVM_OTHERS /uvm_pkg::uvm_hdl_deposit/uvm_hdl_deposit
add wave -noupdate -group UVM_OTHERS /uvm_pkg::uvm_hdl_deposit/value
add wave -noupdate -group UVM_OTHERS /uvm_pkg::uvm_hdl_force/uvm_hdl_force
add wave -noupdate -group UVM_OTHERS /uvm_pkg::uvm_hdl_force/value
add wave -noupdate -group UVM_OTHERS /uvm_pkg::uvm_hdl_force_time/value
add wave -noupdate -group UVM_OTHERS /uvm_pkg::uvm_hdl_force_time/force_time
add wave -noupdate -group UVM_OTHERS /uvm_pkg::uvm_hdl_release_and_read/uvm_hdl_release_and_read
add wave -noupdate -group UVM_OTHERS /uvm_pkg::uvm_hdl_release_and_read/value
add wave -noupdate -group UVM_OTHERS /uvm_pkg::uvm_hdl_release/uvm_hdl_release
add wave -noupdate -group UVM_OTHERS /uvm_pkg::uvm_hdl_read/uvm_hdl_read
add wave -noupdate -group UVM_OTHERS /uvm_pkg::uvm_hdl_read/value
add wave -noupdate -group UVM_OTHERS /uvm_pkg::uvm_dpi_regexec/uvm_dpi_regexec
add wave -noupdate -group UVM_OTHERS /uvm_pkg::uvm_re_match/uvm_re_match
add wave -noupdate -group UVM_OTHERS /uvm_pkg::uvm_radix_to_string/radix
add wave -noupdate -group UVM_OTHERS /uvm_pkg::uvm_status_container::print_matches
add wave -noupdate -group UVM_OTHERS /uvm_pkg::uvm_instance_scope/c
add wave -noupdate -group UVM_OTHERS /uvm_pkg::uvm_instance_scope/pos
add wave -noupdate -group UVM_OTHERS /uvm_pkg::uvm_oneway_hash/uvm_oneway_hash
add wave -noupdate -group UVM_OTHERS /uvm_pkg::uvm_oneway_hash/seed
add wave -noupdate -group UVM_OTHERS /uvm_pkg::uvm_oneway_hash/msb
add wave -noupdate -group UVM_OTHERS /uvm_pkg::uvm_oneway_hash/current_byte
add wave -noupdate -group UVM_OTHERS /uvm_pkg::uvm_oneway_hash/crc1
add wave -noupdate -group UVM_OTHERS /uvm_pkg::uvm_create_random_seed/uvm_create_random_seed
add wave -noupdate -group UVM_OTHERS /uvm_pkg::uvm_leaf_scope/scope_separator
add wave -noupdate -group UVM_OTHERS /uvm_pkg::uvm_leaf_scope/bracket_match
add wave -noupdate -group UVM_OTHERS /uvm_pkg::uvm_leaf_scope/pos
add wave -noupdate -group UVM_OTHERS /uvm_pkg::uvm_leaf_scope/bmatches
add wave -noupdate -group UVM_OTHERS /uvm_pkg::uvm_vector_to_string/value
add wave -noupdate -group UVM_OTHERS /uvm_pkg::uvm_vector_to_string/size
add wave -noupdate -group UVM_OTHERS /uvm_pkg::uvm_vector_to_string/radix
add wave -noupdate -group UVM_OTHERS /uvm_pkg::uvm_get_array_index_int/uvm_get_array_index_int
add wave -noupdate -group UVM_OTHERS /uvm_pkg::uvm_get_array_index_int/is_wildcard
add wave -noupdate -group UVM_OTHERS /uvm_pkg::uvm_get_array_index_int/i
add wave -noupdate -group UVM_OTHERS /uvm_pkg::uvm_get_array_index_string/is_wildcard
add wave -noupdate -group UVM_OTHERS /uvm_pkg::uvm_get_array_index_string/i
add wave -noupdate -group UVM_OTHERS /uvm_pkg::uvm_is_array/uvm_is_array
add wave -noupdate -group UVM_OTHERS /uvm_pkg::uvm_object::use_uvm_seeding
add wave -noupdate -group UVM_OTHERS /uvm_pkg::uvm_object::m_inst_count
add wave -noupdate -group UVM_OTHERS /uvm_pkg::uvm_object::copy/depth
add wave -noupdate -group UVM_OTHERS /uvm_pkg::uvm_object::compare/style
add wave -noupdate -group UVM_OTHERS /uvm_pkg::uvm_factory::m_debug_pass
add wave -noupdate -group UVM_OTHERS /uvm_pkg::uvm_spell_chkr::uvm_spell_chkr__1::max
add wave -noupdate -group UVM_OTHERS /uvm_pkg::uvm_resource_options::auditing
add wave -noupdate -group UVM_OTHERS /uvm_pkg::uvm_resource_base::default_precedence
add wave -noupdate -group UVM_OTHERS /uvm_pkg::uvm_resource_pool::m_has_wildcard_names
add wave -noupdate -group UVM_OTHERS /uvm_pkg::uvm_resource_db_options::ready
add wave -noupdate -group UVM_OTHERS /uvm_pkg::uvm_resource_db_options::tracing
add wave -noupdate -group UVM_OTHERS /uvm_pkg::uvm_config_db_options::ready
add wave -noupdate -group UVM_OTHERS /uvm_pkg::uvm_config_db_options::tracing
add wave -noupdate -group UVM_OTHERS /uvm_pkg::uvm_recorder::handle
add wave -noupdate -group UVM_OTHERS /uvm_pkg::uvm_callbacks_base::m_tracing
add wave -noupdate -group UVM_OTHERS /uvm_pkg::uvm_report_catcher::m_register_cb_uvm_report_catcher
add wave -noupdate -group UVM_OTHERS /uvm_pkg::uvm_report_catcher::m_modified_severity
add wave -noupdate -group UVM_OTHERS /uvm_pkg::uvm_report_catcher::m_modified_verbosity
add wave -noupdate -group UVM_OTHERS /uvm_pkg::uvm_report_catcher::m_line_number
add wave -noupdate -group UVM_OTHERS /uvm_pkg::uvm_report_catcher::m_modified_action
add wave -noupdate -group UVM_OTHERS /uvm_pkg::uvm_report_catcher::m_set_action_called
add wave -noupdate -group UVM_OTHERS /uvm_pkg::uvm_report_catcher::m_demoted_fatal
add wave -noupdate -group UVM_OTHERS /uvm_pkg::uvm_report_catcher::m_demoted_error
add wave -noupdate -group UVM_OTHERS /uvm_pkg::uvm_report_catcher::m_demoted_warning
add wave -noupdate -group UVM_OTHERS /uvm_pkg::uvm_report_catcher::m_caught_fatal
add wave -noupdate -group UVM_OTHERS /uvm_pkg::uvm_report_catcher::m_caught_error
add wave -noupdate -group UVM_OTHERS /uvm_pkg::uvm_report_catcher::m_caught_warning
add wave -noupdate -group UVM_OTHERS /uvm_pkg::uvm_report_catcher::DO_NOT_CATCH
add wave -noupdate -group UVM_OTHERS /uvm_pkg::uvm_report_catcher::DO_NOT_MODIFY
add wave -noupdate -group UVM_OTHERS /uvm_pkg::uvm_report_catcher::m_debug_flags
add wave -noupdate -group UVM_OTHERS /uvm_pkg::uvm_report_catcher::m_orig_severity
add wave -noupdate -group UVM_OTHERS /uvm_pkg::uvm_report_catcher::m_orig_action
add wave -noupdate -group UVM_OTHERS /uvm_pkg::uvm_report_catcher::m_orig_verbosity
add wave -noupdate -group UVM_OTHERS /uvm_pkg::uvm_report_catcher::do_report
add wave -noupdate -group UVM_OTHERS /uvm_pkg::uvm_report_catcher::process_all_report_catchers/in_catcher
add wave -noupdate -group UVM_OTHERS /uvm_pkg::uvm_report_handler::m_relnotes_done
add wave -noupdate -group UVM_OTHERS /uvm_pkg::uvm_phase::m_phase_trace
add wave -noupdate -group UVM_OTHERS /uvm_pkg::uvm_phase::m_use_ovm_run_semantic
add wave -noupdate -group UVM_OTHERS /uvm_pkg::uvm_phase::m_print_successors/level
add wave -noupdate -group UVM_OTHERS /uvm_pkg::uvm_component::m_config_set
add wave -noupdate -group UVM_OTHERS /uvm_pkg::uvm_component::print_config_matches
add wave -noupdate -group UVM_OTHERS /uvm_pkg::uvm_component::print_config_settings/have_been_warned
add wave -noupdate -group UVM_OTHERS /uvm_pkg::uvm_component::m_set_cl_verb/first
add wave -noupdate -group UVM_OTHERS /uvm_pkg::uvm_component::m_set_cl_sev/first
add wave -noupdate -group UVM_OTHERS /uvm_pkg::uvm_root::set_timeout/m_uvm_timeout_overridable
add wave -noupdate -group UVM_OTHERS /uvm_pkg::uvm_callbacks_objection::m_register_cb_uvm_objection_callback
add wave -noupdate -group UVM_OTHERS /uvm_pkg::set_global_timeout/timeout
add wave -noupdate -group UVM_OTHERS /uvm_pkg::set_global_timeout/overridable
add wave -noupdate -group UVM_OTHERS /uvm_pkg::set_global_stop_timeout/timeout
add wave -noupdate -group UVM_OTHERS /uvm_pkg::uvm_report_enabled/uvm_report_enabled
add wave -noupdate -group UVM_OTHERS /uvm_pkg::uvm_report_enabled/verbosity
add wave -noupdate -group UVM_OTHERS /uvm_pkg::uvm_report_enabled/severity
add wave -noupdate -group UVM_OTHERS /uvm_pkg::uvm_report/severity
add wave -noupdate -group UVM_OTHERS /uvm_pkg::uvm_report/verbosity
add wave -noupdate -group UVM_OTHERS /uvm_pkg::uvm_report/line
add wave -noupdate -group UVM_OTHERS /uvm_pkg::uvm_report_info/verbosity
add wave -noupdate -group UVM_OTHERS /uvm_pkg::uvm_report_info/line
add wave -noupdate -group UVM_OTHERS /uvm_pkg::uvm_report_warning/verbosity
add wave -noupdate -group UVM_OTHERS /uvm_pkg::uvm_report_warning/line
add wave -noupdate -group UVM_OTHERS /uvm_pkg::uvm_report_error/verbosity
add wave -noupdate -group UVM_OTHERS /uvm_pkg::uvm_report_error/line
add wave -noupdate -group UVM_OTHERS /uvm_pkg::uvm_report_fatal/verbosity
add wave -noupdate -group UVM_OTHERS /uvm_pkg::uvm_report_fatal/line
add wave -noupdate -group UVM_OTHERS /uvm_pkg::uvm_string_to_severity/uvm_string_to_severity
add wave -noupdate -group UVM_OTHERS /uvm_pkg::uvm_string_to_severity/sev
add wave -noupdate -group UVM_OTHERS /uvm_pkg::set_config_int/value
add wave -noupdate -group UVM_OTHERS /uvm_pkg::set_config_object/clone
add wave -noupdate -group UVM_OTHERS /uvm_pkg::uvm_is_match/uvm_is_match
add wave -noupdate -group UVM_OTHERS /uvm_pkg::uvm_wait_for_nba_region/nba
add wave -noupdate -group UVM_OTHERS /uvm_pkg::uvm_wait_for_nba_region/next_nba
add wave -noupdate -group UVM_OTHERS /uvm_pkg::uvm_sequence_item::issued1
add wave -noupdate -group UVM_OTHERS /uvm_pkg::uvm_sequence_item::issued2
add wave -noupdate -group UVM_OTHERS /uvm_pkg::uvm_sequencer_base::g_request_id
add wave -noupdate -group UVM_OTHERS /uvm_pkg::uvm_sequencer_base::g_sequence_id
add wave -noupdate -group UVM_OTHERS /uvm_pkg::uvm_sequencer_base::g_sequencer_id
add wave -noupdate -group UVM_OTHERS /uvm_pkg::uvm_tlm_time::m_resolution
add wave -noupdate -group UVM_OTHERS /uvm_pkg::uvm_reg_backdoor::m_register_cb_uvm_reg_cbs
add wave -noupdate -group UVM_OTHERS /uvm_pkg::uvm_reg_field::m_max_size
add wave -noupdate -group UVM_OTHERS /uvm_pkg::uvm_reg_field::m_predefined
add wave -noupdate -group UVM_OTHERS /uvm_pkg::uvm_reg_field::m_register_cb_uvm_reg_cbs
add wave -noupdate -group UVM_OTHERS /uvm_pkg::uvm_vreg_field::m_register_cb_uvm_vreg_field_cbs
add wave -noupdate -group UVM_OTHERS /uvm_pkg::uvm_reg::m_max_size
add wave -noupdate -group UVM_OTHERS /uvm_pkg::uvm_reg::m_register_cb_uvm_reg_cbs
add wave -noupdate -group UVM_OTHERS /uvm_pkg::uvm_vreg::m_register_cb_uvm_vreg_cbs
add wave -noupdate -group UVM_OTHERS /uvm_pkg::uvm_mem::m_max_size
add wave -noupdate -group UVM_OTHERS /uvm_pkg::uvm_mem::m_register_cb_uvm_reg_cbs
add wave -noupdate -group UVM_OTHERS /uvm_pkg::uvm_reg_block::id
add wave -noupdate -group UVM_OTHERS /questa_uvm_pkg::questa_uvm_recorder::UVM_TR_TRACE_API
add wave -noupdate -group UVM_OTHERS /questa_uvm_pkg::questa_uvm_recorder::UVM_TR_TRACE_API_DETAIL
add wave -noupdate -group UVM_OTHERS /questa_uvm_pkg::questa_uvm_recorder::UVM_TR_TRACE_PLI_CALLS
add wave -noupdate -group UVM_OTHERS /questa_uvm_pkg::questa_uvm_recorder::uvm_tr_initialized
add wave -noupdate -group UVM_OTHERS /questa_uvm_pkg::questa_configdb::private_getConfigData/save_index
add wave -noupdate -group UVM_OTHERS /questa_uvm_pkg::questa_configdb::getConfigData/save_start_index
add wave -noupdate -group UVM_OTHERS /questa_uvm_pkg::questa_configdb::getConfigData/save_buf_size
add wave -noupdate -group UVM_OTHERS /questa_uvm_pkg::questa_configdb::getConfigDataWithAccesses/var_save_start_index
add wave -noupdate -group UVM_OTHERS /questa_uvm_pkg::questa_configdb::getConfigDataWithAccesses/var_save_buf_size
add wave -noupdate -group UVM_OTHERS /questa_uvm_pkg::questa_uvm::is_questa_uvm_pkg_inited
add wave -noupdate -group UVM_OTHERS /questa_uvm_pkg::questa_uvm::m_the_default_setting
add wave -noupdate -group UVM_OTHERS /questa_uvm_pkg::questa_uvm::major_revision
add wave -noupdate -group UVM_OTHERS /questa_uvm_pkg::questa_uvm::minor_revision
add wave -noupdate -group UVM_OTHERS /questa_uvm_pkg::questa_uvm::patch_revision
add wave -noupdate -group UVM_OTHERS /std::mailbox::mailbox__1::try_put/try_put
add wave -noupdate -group UVM_OTHERS /std::mailbox::mailbox__1::try_get/try_get
add wave -noupdate -group UVM_OTHERS /std::mailbox::mailbox__1::try_get/message
add wave -noupdate -group UVM_OTHERS /std::mailbox::mailbox__1::try_peek/try_peek
add wave -noupdate -group UVM_OTHERS /std::mailbox::mailbox__1::try_peek/message
add wave -noupdate -group UVM_OTHERS /std::mailbox::mailbox__2::try_put/try_put
add wave -noupdate -group UVM_OTHERS /std::mailbox::mailbox__2::try_get/try_get
add wave -noupdate -group UVM_OTHERS /std::mailbox::mailbox__2::try_get/message
add wave -noupdate -group UVM_OTHERS /std::mailbox::mailbox__2::try_peek/try_peek
add wave -noupdate -group UVM_OTHERS /std::mailbox::mailbox__2::try_peek/message
add wave -noupdate -group UVM_OTHERS /std::mailbox::mailbox__3::try_put/try_put
add wave -noupdate -group UVM_OTHERS /std::mailbox::mailbox__3::try_get/try_get
add wave -noupdate -group UVM_OTHERS /std::mailbox::mailbox__3::try_get/message
add wave -noupdate -group UVM_OTHERS /std::mailbox::mailbox__3::try_peek/try_peek
add wave -noupdate -group UVM_OTHERS /std::mailbox::mailbox__3::try_peek/message
add wave -noupdate -group UVM_OTHERS /std::mailbox::mailbox__4::try_put/try_put
add wave -noupdate -group UVM_OTHERS /std::mailbox::mailbox__4::try_get/try_get
add wave -noupdate -group UVM_OTHERS /std::mailbox::mailbox__4::try_get/message
add wave -noupdate -group UVM_OTHERS /std::mailbox::mailbox__4::try_peek/try_peek
add wave -noupdate -group UVM_OTHERS /std::mailbox::mailbox__4::try_peek/message
add wave -noupdate /tb_top/vif/drv_cb/drv_cb_event
add wave -noupdate /tb_top/vif/mon_cb/mon_cb_event
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {15000 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 494
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ps} {81376 ps}
