INC_PATH_OPENCV = /usr/local/include
LIB_PATH_OPENCV = /usr/local/lib

LIB_OPTION = -lopencv_features2d -lopencv_imgcodecs  -lopencv_photo -lopencv_calib3d -lopencv_core -lopencv_highgui -lopencv_ml -lopencv_imgproc -lopencv_video -lopencv_videoio -lopencv_videostab -lopencv_objdetect -lopencv_face


CC  = g++

lab : 
	$(CC) -pipe lab.cpp -L$(LIB_PATH_OPENCV) $(LIB_OPTION) -I$(INC_PATH_OPENCV) -o lab -O3

clean :
	@rm -rf *.o pre_process
