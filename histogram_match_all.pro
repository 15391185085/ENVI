PRO histogram_match_all
;relative normalization
;批量匀色工具，只匀色不镶嵌
;20190214 修改代码直方图匹配。
COMPILE_OPT IDL2
  ;Get ENVI session
  e = ENVI()
  
  ;设置错误日志
  b=bin_date(systime())
  logFile = 'C:\Temp\test2\err_'+string(b[0],b[1],b[2],b[3],b[4],b[5], format='(i-4,"_",i02,"_", i02,"_", i02,"_",i02,"_",i02)')+'.log'
  OPENW,lun,logFile,/GET_LUN
  ;Determine input scenes?
  DIRPATH='C:\Temp\test1\';待校正影像路径
  RESPATH='C:\Temp\test2\';校正后影像存放路径
  
  refname='C:\Temp\test2\Func_GF2_E112_2_N41_5_20180604_19_fus_tif_R1C2.dat';待参考影像路径\名称
  
  filelist = REVERSE(FILE_SEARCH(DIRPATH, '*.dat'))
  
  str = ['Input Path: ' + DIRPATH,$
    'Output Path: ' + RESPATH]
  IF FILE_TEST(refname) EQ 0 THEN BEGIN
    PRINTF,lun,'待参考影像不存在：'+refname
    PRINTF,lun,'匀色处理完成'

    FREE_LUN,lun
    SPAWN, logFile, /HIDE
    RETURN
  ENDIF
  ENVI_REPORT_INIT, str, title="匀色处理中...", base=base ,/INTERRUPT
  ENVI_REPORT_INC, base, filelist.LENGTH
  FOR i=0,n_elements(filelist)-1 DO BEGIN

    ;合成输出文件位置
    ENVI_REPORT_STAT,base, i, filelist.LENGTH, CANCEL=cancelvar
    ;判断是否点击取消
    IF cancelVar EQ 1 THEN BEGIN
      tmp = DIALOG_MESSAGE('点击了取消在第'+STRING(i)+'个文件',/info)
      ENVI_REPORT_INIT, base=base, /finish
      BREAK
    ENDIF
    
    ;捕获异常
    CATCH, error_status
    IF error_status NE 0 THEN BEGIN
      PRINTF,lun,'异常的文件：'+filelist[i]
      PRINTF,lun,"对应的错误： "+!ERROR_STATE.MSG
      IF AdjustRaster NE !NULL THEN BEGIN
        AdjustRaster.Close
      ENDIF
      IF MatchedRaster NE !NULL THEN BEGIN
        MatchedRaster.Close
      ENDIF
      IF ReferenceRaster NE !NULL THEN BEGIN
        ReferenceRaster.Close
      ENDIF
      continue
    ENDIF
    
    filename=STRMID(filelist[i],0,STRLEN(filelist[i])-4)
    basename=FILE_BASENAME(filename)
    resname=respath+basename+'_histogram.dat'
    ;开始匀色
    IF (FILE_TEST(resname) EQ 0) and (filelist[i] ne refname) THEN BEGIN
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
    ENDIF
  ENDFOR
  print,'匀色处理完成'
  PRINTF,lun,'匀色处理完成'

  ENVI_REPORT_INIT, base=base, /finish
  CATCH, /CANCEL
  FREE_LUN,lun
  SPAWN, logFile, /HIDE
END