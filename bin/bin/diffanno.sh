for i in *.exp.xls
do
/mnt/ilustre/users/bingxu.liu/workspace/RNA_Pipeline/RNAseq_ToolBox_v1410 de_go unigene_GO.list $i  >$i.go.log 2>&1
/mnt/ilustre/users/bingxu.liu/workspace/RNA_Pipeline/RNAseq_ToolBox_v1410 de_kegg unigene_pathway.txt $i >$i.kegg.log 2>&1
rm */*.m
done
wait
cd -
