library(RamiGO)
library(gplots)
gos<-read.delim("example",header=TRUE,check.names=FALSE,sep="\t",row.names=1)
pcolors <- c("red","green")
color.palette <- colorRampPalette(colors=pcolors)
color.gradient <- color.palette(128)
log_pvalue = round (-(log(gos[[5]])+10)*8)
goIDs=rownames(gos) 
color=rainbow(length(goIDs), s = 1, v = 1, start = 0, end = 1/6, alpha = 1)
#pngRes <- getAmigoTree(goIDs=goIDs, color=color, filename="example", picType="png",saveResult = TRUE)
#svgRes <- getAmigoTree(goIDs=goIDs, color=color, filename="example", picType="svg",saveResult = TRUE)

all<-ls()
while(!("svgRes"%in%all)){
svgRes <- getAmigoTree(goIDs=goIDs, color=color, filename="example", picType="svg",saveResult = TRUE)
all<-ls()
}

while(!("pngRes"%in%all)){
pngRes <- getAmigoTree(goIDs=goIDs, color=color, filename="example", picType="png",saveResult = TRUE)
all<-ls()
}
