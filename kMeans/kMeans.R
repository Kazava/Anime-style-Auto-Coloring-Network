if("EBImage" %in% rownames(installed.packages()) == FALSE) 
{
  source("https://bioconductor.org/biocLite.R")
  biocLite("EBImage")
  biocLite()
}
if("stats" %in% rownames(installed.packages()) == FALSE) 
{
  install.packages("stats")
}
if("ggplot2" %in% rownames(installed.packages()) == FALSE) 
{
  install.packages("ggplot2")
}
library(stats)
library(EBImage)
library(ggplot2)

local_matrix_f <- function(df, rnum, dfnum)
{
  local_image_matrix <- data.frame(matrix(nrow = 12544, ncol = (1+28)*(1+28)))
  conv_df <- data.frame(matrix(ncol = 112+14+14, nrow = 112+14+14))
  conv_df[,] <- rep(0, (112+28)*(112+28))
  conv_df[(1+14):(112+14), (1+14):(112+14)] <- df
  
  for(i in 1:(dfnum))
  {
    from_x = rnum$x[i]
    from_y = rnum$y[i]
    to_x = from_x + 28
    to_y = from_y + 28
    local_image_matrix[i,] = as.vector(as.matrix(conv_df[from_y:to_y, from_x:to_x]))
    print(i)
  }
  
  return (local_image_matrix)
}
#############################################################
rnum <- data.frame(
  x = rep(1:112, 112),
  y = rep(1:112, each = 112)
)

im <- EBImage::readImage("basic_target.jpg")
im <- imageData(im)
local_image_matrix = local_matrix_f(im, rnum, (112*112))
write.table(local_image_matrix[1:6000,], "input_matrix1.csv", row.names = F, col.names = F, sep=",")
write.table(local_image_matrix[6001:12544,], "input_matrix2.csv", row.names = F, col.names = F, sep=",")
#################################################################
im <- EBImage::readImage("canny_target.jpg")
im.g2edge <- imageData(im)
local_image_matrix = local_matrix_f(im.g2edge, rnum, (112*112))
write.table(local_image_matrix[1:6000,], "input_matrix1(canny).csv", row.names = F, col.names = F, sep=",")
write.table(local_image_matrix[6001:12544,], "input_matrix2(canny).csv", row.names = F, col.names = F, sep=",")
###############################################################
edge_point <- read.table("FAST_target.csv", header = FALSE, sep = ",")
matrix_map <- data.frame(matrix(nrow = 112, ncol = 112))
matrix_map[,] <- rep(0, 112*112)
for(i in 1:nrow(edge_point))
{
  x = edge_point$V1[i]
  y = edge_point$V2[i]
  matrix_map[y, x] = 1
  matrix_map[y+1, x] = 1
  matrix_map[y-1, x] = 1
  matrix_map[y, x+1] = 1
  matrix_map[y, x-1] = 1
}
local_image_matrix = local_matrix_f(matrix_map, rnum, (112*112))
write.table(local_image_matrix[1:6000,], "input_matrix1(FAST).csv", row.names = F, col.names = F, sep=",")
write.table(local_image_matrix[6001:12544,], "input_matrix2(FAST).csv", row.names = F, col.names = F, sep=",")
##############################################################
im <- EBImage::readImage("source4knn.jpg")
df_im = imageData(im)
df_im[,,1] = t(df_im[,,1])
df_im[,,2] = t(df_im[,,2])
df_im[,,3] = t(df_im[,,3])

imgDm <- dim(df_im)
imgRGB <- data.frame(
  x = rep(1:imgDm[2], each = imgDm[1]),
  y = rep(imgDm[1]:1, imgDm[2]),
  R = as.vector(df_im[,,1]),
  G = as.vector(df_im[,,2]),
  B = as.vector(df_im[,,3])
)

plotTheme <- function() {
  theme(
    panel.background = element_rect(
      size = 3,
      colour = "black",
      fill = "white"),
    axis.ticks = element_line(
      size = 2),
    panel.grid.major = element_line(
      colour = "gray80",
      linetype = "dotted"),
    panel.grid.minor = element_line(
      colour = "gray90",
      linetype = "dashed"),
    axis.title = element_text(
      size = rel(1.2),
      face = "bold"),
    axis.title.y = element_text(
      size = rel(1.2),
      face = "bold"),
    plot.title = element_text(
      size = 20,
      face = "bold",
      vjust = 1.5)
  )
}

p1 = ggplot(data = imgRGB, aes(x = x, y = y)) +
  geom_point(colour = rgb(imgRGB[c("R", "G", "B")])) +
  labs(title = "Source Image") +
  xlab("x") +
  ylab("y") +
  plotTheme()
plot(p1)
ggsave(filename="Source Image.jpg", plot=p1)

kClusters <- 24
kMeans <- kmeans(imgRGB[, c("R", "G", "B")], centers = kClusters)
kColours <- rgb(kMeans$centers[kMeans$cluster,])
imgRGB$label <- kMeans$cluster

p2 = ggplot(data = imgRGB, aes(x = x, y = y)) +
  geom_point(colour = kColours) +
  labs(title = "Clustered Source Image") +
  xlab("x") +
  ylab("y") +
  plotTheme()

plot(p2)
ggsave(filename="Clustered Source Image.jpg", plot=p2)

df = data.frame(
  red = matrix(df_im[,,1], ncol=1),
  green = matrix(df_im[,,2], ncol=1),
  blue=matrix(df_im[,,3], ncol=1)
)

df$label = kMeans$cluster

colors = data.frame(
  label = 1:nrow(kMeans$centers),
  R = kMeans$centers[,"R"],
  G = kMeans$centers[,"G"],
  B = kMeans$centers[,"B"]
)

df$order = 1:nrow(df)
df = merge(df, colors)
df = df[order(df$order),]
df$order = NULL

PCA = prcomp(df[,c("red", "green", "blue")], center = TRUE, scale = TRUE)
df$u = PCA$x[,1]
df$v = PCA$x[,2]

summary(PCA)

p3 = ggplot(df, aes(x=u, y=v, col=rgb(red, green, blue))) +
  geom_point(size=2) + scale_color_identity()
plot(p3)

ggsave(filename="Ground Truth Color.jpg", plot=p3)

p4 = ggplot(df, aes(x=u, y=v, col=rgb(R, G, B))) +
  geom_point(size=2) + scale_color_identity()
plot(p4)
ggsave(filename="Clustered Color.jpg", plot=p4)

imgRGB$y <- abs(113 - imgRGB$y)

p5 <- ggplot(imgRGB, aes(x, y, label = label)) + geom_text(aes(colour=factor(label)), check_overlap = TRUE) + scale_y_reverse()
plot(p5)
ggsave(filename="Labeled Clustered Color.jpg", plot=p5)

categorial_matrix <- data.frame(matrix(nrow=112*112, ncol=1))
categorial_matrix[,1] <- imgRGB$label
categorial_matrix[,1] <- factor(categorial_matrix[,1])
names(categorial_matrix) <- "label"
categorial_matrix <- model.matrix(~ . + 0, data=categorial_matrix, contrasts.arg = lapply(categorial_matrix, contrasts, contrasts=FALSE)) # One-Hot Encoding
categorial_matrix <- data.frame(categorial_matrix)
categorial_matrix$x <- imgRGB$x
categorial_matrix$y <- imgRGB$y
##################################################################
im.g <- EBImage::readImage("basic_source.jpg")
gray_df_im <- imageData(im.g)

rnum <- data.frame(matrix(nrow = 12432, ncol = 2))
names(rnum) = c('x', 'y')
s <- sample(c(113:12544), 12432)
rnum$y <- s%%112
rnum$x <- (s - rnum$y)/112
rnum$y <- rnum$y+1

local_image_matrix = local_matrix_f(gray_df_im, rnum, 12432)
temp = merge(categorial_matrix, rnum, by=c("x", "y"), all.y = TRUE)
temp = temp[order(match(paste(temp[,1],temp[,2]),paste(rnum[,1],rnum[,2]))),]
temp$x = NULL
temp$y = NULL

X = local_image_matrix[1:12000,]
Y = temp[1:12000,]
testX = local_image_matrix[12001:12432,]
testY = temp[12001:12432,]

write.table(X[1:6000,], "X1.csv", row.names = F, col.names = F, sep=",")
write.table(X[6001:12000,], "X2.csv", row.names = F, col.names = F, sep=",")
write.table(Y, "Y.csv", row.names = F, col.names = F, sep=",")
write.table(testX, "testX.csv", row.names = F, col.names = F, sep=",")
write.table(testY, "testY.csv", row.names = F, col.names = F, sep=",")

saveRDS(colors, "label-color.rds")
###########################################################
im.g2edge <- EBImage::readImage("canny_source.jpg")
df_im.g2edge <- imageData(im.g2edge)
local_image_matrix = local_matrix_f(df_im.g2edge, rnum, 12432)

X = local_image_matrix[1:12000,]
testX = local_image_matrix[12001:12432,]

write.table(X[1:6000,], "X1(canny).csv", row.names = F, col.names = F, sep=",")
write.table(X[6001:12000,], "X2(canny).csv", row.names = F, col.names = F, sep=",")
write.table(testX, "testX(canny).csv", row.names = F, col.names = F, sep=",")
###########################################################
edge_point <- read.table("FAST_source.csv", header = FALSE, sep = ",")
matrix_map <- data.frame(matrix(nrow = 112, ncol = 112))
matrix_map[,] <- rep(0, 112*112)
for(i in 1:nrow(edge_point))
{
  x = edge_point$V1[i]
  y = edge_point$V2[i]
  matrix_map[y, x] = 1
  matrix_map[y+1, x] = 1
  matrix_map[y-1, x] = 1
  matrix_map[y, x+1] = 1
  matrix_map[y, x-1] = 1
}
local_image_matrix = local_matrix_f(matrix_map, rnum, 12432)

X = local_image_matrix[1:12000,]
testX = local_image_matrix[12001:12432,]

write.table(X[1:6000,], "X1(FAST).csv", row.names = F, col.names = F, sep=",")
write.table(X[6001:12000,], "X2(FAST).csv", row.names = F, col.names = F, sep=",")
write.table(testX, "testX(FAST).csv", row.names = F, col.names = F, sep=",")
