PRO histogram_match_all
;relative normalization
;批量匀色工具，只匀色不镶嵌
;使用直方图匹配法
COMPILE_OPT IDL2
  ;Get ENVI session
  e = ENVI()
  
  filelist = DIALOG_PICKFILE(/MULTIPLE_FILES,FILTER = ['*.dat'], TITLE='选择待校正影像')
  print,filelist
  refname = DIALOG_PICKFILE(FILTER = ['*.dat'], TITLE='选择待参考影像')
  print,refname
  RESPATH = DIALOG_PICKFILE(/DIRECTORY, TITLE='选择校正后影像存放路径')
  print,RESPATH
  
  ENVI_REPORT_INIT, ['校正后影像存放路径: ' + RESPATH], title="匀色处理中...", base=base ,/INTERRUPT
  ENVI_REPORT_INC, base, filelist.LENGTH
  
  ;捕获异常
  CATCH, error_status
  FOR i=0,n_elements(filelist)-1 DO BEGIN    
    IF error_status NE 0 THEN BEGIN

      IF AdjustRaster NE !NULL THEN BEGIN
        AdjustRaster.Close
      ENDIF
      IF MatchedRaster NE !NULL THEN BEGIN
        MatchedRaster.Close
      ENDIF
      IF ReferenceRaster NE !NULL THEN BEGIN
        ReferenceRaster.Close
      ENDIF
      tmp = DIALOG_MESSAGE('文件：'+filelist[i] + "，处理失败!",/info)
      ENVI_REPORT_INIT, base=base, /finish
      RETURN
    ENDIF
    
    print,'开始'+systime()

    ;合成输出文件位置
    ENVI_REPORT_STAT,base, i, filelist.LENGTH, CANCEL=cancelvar
    ;判断是否点击取消
    IF cancelVar EQ 1 THEN BEGIN
      tmp = DIALOG_MESSAGE('点击了取消在第'+STRING(i)+'个文件',/info)
      ENVI_REPORT_INIT, base=base, /finish
      RETURN
    ENDIF
    
    filename=STRMID(filelist[i],0,STRLEN(filelist[i])-4)
    basename=FILE_BASENAME(filename)
    resname=respath+basename+'_histogram.dat'
    ;开始匀色
    IF (FILE_TEST(resname) EQ 1) or (filelist[i] EQ refname) THEN BEGIN
      CONTINUE
    ENDIF
    ;待校正和待参考不能是一个路径，且输出路径不能被占用
    ;获取待校正影像
    ReferenceRaster = e.OpenRaster(refname, DATA_IGNORE_VALUE=0)
    AdjustRaster = e.OpenRaster(filelist[i], DATA_IGNORE_VALUE=0)
    tiles = AdjustRaster.CreateTileIterator(BANDS=0)
    Adjust_Sub_Rect = tiles.SUB_RECT

    IF ~N_ELEMENTS(AdjustRaster) THEN RETURN
    AdjustFile = AdjustRaster.URI
    
    ;计算Adjust图像的输出范围的文件坐标
    FileX = [Adjust_Sub_Rect[0], Adjust_Sub_Rect[2]]
    FileY = [Adjust_Sub_Rect[1], Adjust_Sub_Rect[3]]
    ;转换为地理坐标
    spatialRef1 = AdjustRaster.SPATIALREF
    spatialRef1.ConvertFileToMap, FileX, FileY, MapX, MapY

    ;建立虚拟镶嵌栅格对象，设置匀色统计全图
    Scenes = [AdjustRaster, ReferenceRaster]
    MosaicRaster = ENVIMOSAICRASTER(Scenes)
    MosaicRaster.COLOR_MATCHING_METHOD = 'histogram matching'
    MosaicRaster.COLOR_MATCHING_STATS = 'entire scene'
    MosaicRaster.COLOR_MATCHING_ACTIONS = ['adjust','reference']

    ;将输出范围地理坐标，转换为镶嵌结果的文件坐标
    MatchedRaster = MosaicRaster.subset(SUB_RECT = [MapX[0],MapY[1],MapX[1],MapY[0]], $
      SPATIALREF = MosaicRaster.SPATIALREF)

    print,'正在输出:'+resname
    ;输出结果
    MatchedRaster.export, resname, 'envi'
    print,'输出完成'
    AdjustRaster.Close
    MatchedRaster.Close
    ReferenceRaster.Close
    print,'完成'+systime()

  ENDFOR
  tmp = DIALOG_MESSAGE('处理完成！',/info)
  ENVI_REPORT_INIT, base=base, /finish
  CATCH, /CANCEL
END