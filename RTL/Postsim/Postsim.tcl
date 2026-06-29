sed 's/qk_dot_/sparse_qk_dot_/g' ../Syn/sparse_attention/sparse_attention_core_syn.v > sparse_attention_core_syn_postsim.v
sed 's/qk_dot_/sparse_qk_dot_/g' ../Syn/sparse_attention/sparse_attention_core_syn.sdf > sparse_attention_core_syn_postsim.sdf
vcs -R -full64 -debug_access tb.v ../Syn/full_attention/full_attention_core_syn.v sparse_attention_core_syn_postsim.v -v tsmc13_neg.v +neg_tchk +define+SDF
