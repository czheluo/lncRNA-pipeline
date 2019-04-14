#!/usr/bin/perl
unless(@ARGV==2){die "Usage: perl $0 <lncRNA orf file><mRNA orf file>\n";}
my $Rlines=<<RL;


library(ggplot2)
lncRNA_orf<-read.table("$ARGV[0]",sep="\t",row.names=1)
mRNA_orf<-read.table("$ARGV[1]",sep="\t",row.names=1)
lncRNA_orf\$Type<-"lncRNA"
mRNA_orf\$Type<-"mRNA"
all<-rbind(lncRNA_orf,mRNA_orf)
all\$log_orf<-log10(all\$V2)
pdf("lncRNA_vs_mRNA_ORF_length_boxplot.pdf")
ggplot(all,aes(x=Type,y=all\$log_orf,fill=Type))+geom_boxplot(aes(outliner.size=0.5))+labs(x="",y="log10(ORF length)",title="lncRNA vs mRNA on ORF length")+theme_bw()
dev.off()


#pvlaue<-wilcox.test(lncRNA_orf\$V2,mRNA_orf\$V2)
#text(1.5,4.5,labels=paste("p_value:",format(pvlaue\$p.value,scientific=TRUE,digit=3)))
RL

my $R_script = "lncRNA_VS_mRNA_orf_boxplot".".r";
open FOUT,">$R_script";
print FOUT $Rlines;
close FOUT;

`Rscript $R_script`;

