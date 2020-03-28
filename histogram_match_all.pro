PRO histogram_match_all
;relative normalization
;������ɫ���ߣ�ֻ��ɫ����Ƕ
;20190214 �޸Ĵ���ֱ��ͼƥ�䡣
COMPILE_OPT IDL2
  ;Get ENVI session
  e = ENVI()
  
  ;���ô�����־
  b=bin_date(systime())
  logFile = 'C:\Temp\test2\err_'+string(b[0],b[1],b[2],b[3],b[4],b[5], format='(i-4,"_",i02,"_", i02,"_", i02,"_",i02,"_",i02)')+'.log'
  OPENW,lun,logFile,/GET_LUN
  ;Determine input scenes?
  DIRPATH='C:\Temp\test1\';��У��Ӱ��·��
  RESPATH='C:\Temp\test2\';У����Ӱ����·��
  
  refname='C:\Temp\test2\Func_GF2_E112_2_N41_5_20180604_19_fus_tif_R1C2.dat';���ο�Ӱ��·��\����
  
  filelist = REVERSE(FILE_SEARCH(DIRPATH, '*.dat'))
  
  str = ['Input Path: ' + DIRPATH,$
    'Output Path: ' + RESPATH]
  IF FILE_TEST(refname) EQ 0 THEN BEGIN
    PRINTF,lun,'���ο�Ӱ�񲻴��ڣ�'+refname
    PRINTF,lun,'��ɫ�������'

    FREE_LUN,lun
    SPAWN, logFile, /HIDE
    RETURN
  ENDIF
  ENVI_REPORT_INIT, str, title="��ɫ������...", base=base ,/INTERRUPT
  ENVI_REPORT_INC, base, filelist.LENGTH
  FOR i=0,n_elements(filelist)-1 DO BEGIN

    ;�ϳ�����ļ�λ��
    ENVI_REPORT_STAT,base, i, filelist.LENGTH, CANCEL=cancelvar
    ;�ж��Ƿ���ȡ��
    IF cancelVar EQ 1 THEN BEGIN
      tmp = DIALOG_MESSAGE('�����ȡ���ڵ�'+STRING(i)+'���ļ�',/info)
      ENVI_REPORT_INIT, base=base, /finish
      BREAK
    ENDIF
    
    ;�����쳣
    CATCH, error_status
    IF error_status NE 0 THEN BEGIN
      PRINTF,lun,'�쳣���ļ���'+filelist[i]
      PRINTF,lun,"��Ӧ�Ĵ��� "+!ERROR_STATE.MSG
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
    ;��ʼ��ɫ
    IF (FILE_TEST(resname) EQ 0) and (filelist[i] ne refname) THEN BEGIN
      ;��У���ʹ��ο�������һ��·���������·�����ܱ�ռ��
      ;��ȡ��У��Ӱ��
      ReferenceRaster = e.OpenRaster(refname, DATA_IGNORE_VALUE=0)
      AdjustRaster = e.OpenRaster(filelist[i], DATA_IGNORE_VALUE=0)
      tiles = AdjustRaster.CreateTileIterator(BANDS=0)
      Adjust_Sub_Rect = tiles.SUB_RECT

      IF ~N_ELEMENTS(AdjustRaster) THEN RETURN
      AdjustFile = AdjustRaster.URI
      
      ;����Adjustͼ��������Χ���ļ�����
      FileX = [Adjust_Sub_Rect[0], Adjust_Sub_Rect[2]]
      FileY = [Adjust_Sub_Rect[1], Adjust_Sub_Rect[3]]
      ;ת��Ϊ��������
      spatialRef1 = AdjustRaster.SPATIALREF
      spatialRef1.ConvertFileToMap, FileX, FileY, MapX, MapY

      ;����������Ƕդ�����������ɫͳ��ȫͼ
      Scenes = [AdjustRaster, ReferenceRaster]
      MosaicRaster = ENVIMOSAICRASTER(Scenes)
      MosaicRaster.COLOR_MATCHING_METHOD = 'histogram matching'
      MosaicRaster.COLOR_MATCHING_STATS = 'entire scene'
      MosaicRaster.COLOR_MATCHING_ACTIONS = ['adjust','reference']

      ;�������Χ�������꣬ת��Ϊ��Ƕ������ļ�����
      MatchedRaster = MosaicRaster.subset(SUB_RECT = [MapX[0],MapY[1],MapX[1],MapY[0]], $
        SPATIALREF = MosaicRaster.SPATIALREF)

      print,'�������:'+resname
      ;������
      MatchedRaster.export, resname, 'envi'
      print,'������'
      AdjustRaster.Close
      MatchedRaster.Close
      ReferenceRaster.Close
    ENDIF
  ENDFOR
  print,'��ɫ�������'
  PRINTF,lun,'��ɫ�������'

  ENVI_REPORT_INIT, base=base, /finish
  CATCH, /CANCEL
  FREE_LUN,lun
  SPAWN, logFile, /HIDE
END