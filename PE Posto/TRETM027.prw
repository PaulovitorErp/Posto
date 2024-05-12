#include 'protheus.ch'
#include 'fwmvcdef.ch'
#include 'topconn.ch'

/*/{Protheus.doc} TRETM027
Ponto de Entrada - Manutenção de Bombas
@author TOTVS
@since 10/04/2014
@version P12
@param Nao recebe parametros
@return nulo
/*/

/***********************/
User Function TRETM027()
/***********************/

Local aParam     	:= PARAMIXB
Local oObj       	:= aParam[1]
Local cIdPonto   	:= aParam[2]
Local cIdModel   	:= IIf( oObj<> NIL, oObj:GetId(), aParam[3] )
Local cClasse    	:= IIf( oObj<> NIL, oObj:ClassName(), '' )
Local xRet       	:= .T.
Local oModel     	:= aParam[1]
Local oModelU00  	:= oModel:GetModel('U00MASTER')
Local nOperation 	:= oModel:GetOperation()

Local oGet1
Local oSay1
Local oSButton1, oSButton2

Local lCanc 		:= .F.
Local lGravaMIF	:= ChkFile("MIF") .AND. MIF->(FieldPos("MIF_CODMAN"))>0
Local _z
Local cCodBom := Space(TamSX3("U00_BOMBA")[1])

Static oDlg

If cIdPonto == 'MODELVLDACTIVE' .AND. nOperation == MODEL_OPERATION_INSERT

	DEFINE MSDIALOG oDlg TITLE "Informe a Bomba" FROM 000, 000  TO 100, 200 COLORS 0, 16777215 PIXEL Style 128

	oDlg:lEscClose	:= .F.

	@ 010, 005 SAY oSay1 PROMPT "Bomba" SIZE 025, 007 OF oDlg COLORS 0,16777215 PIXEL
	@ 010, 027 MSGET oGet1 VAR cCodBom SIZE 060, 010 OF oDlg COLORS 0,16777215 F3 "MHY" Valid (!Empty(cCodBom) .And. ValBomba(cCodBom)) PIXEL HASBUTTON

	DEFINE SBUTTON oSButton1 FROM 036, 030 TYPE 01 OF oDlg ENABLE ACTION oDlg:End()
	DEFINE SBUTTON oSButton2 FROM 036, 060 TYPE 02 OF oDlg ENABLE ACTION {|| oDlg:End(),lCanc := .T.}

	ACTIVATE MSDIALOG oDlg CENTERED

	If lCanc
		Help( ,, 'Help',, 'Operação cancelada.', 1, 0 )
		Return .F.
	Endif

	oModelU00:Activate()
	oModelU00:SetValue('U00_BOMBA',cCodBom)
Endif

If cIdPonto == 'MODELCOMMITNTTS' 

	oModel     := FWModelActive()
	oView 	   := FWViewActive()
	oModelU00  := oModel:GetModel('U00MASTER')
	oModelU01  := oModel:GetModel('U01DETAIL')
	oModelU02  := oModel:GetModel('U02DETAIL')

	cCodBom    := oModelU00:GetValue('U00_BOMBA')

	_aArea     :=GetArea()

	//Atualizar tabela de lacres - MIB
	DbSelectArea("MIB")
	MIB->(DbSetOrder(3)) //MIB_FILIAL+MIB_CODBOM+MIB_NROLAC
	If MIB->(DbSeek(xFilial("MIB")+cCodBom))
		While MIB->MIB_FILIAL == xFilial("MIB") .AND. MIB->MIB_CODBOM == cCodBom
			if empty(MIB->MIB_DTINAT)
				Reclock("MIB", .F.)
					//MIB->(dbDelete())
					MIB->MIB_STATUS := "I" //inutilizado
					MIB->MIB_DTINAT := dDataBase
				Msunlock()
			endif

			MIB->(DbSkip())
		Enddo
	Endif
	If nOperation == MODEL_OPERATION_INSERT
		For _z := 1 to oModelU01:Length()
			oModelU01:Goline(_z)

			Reclock("MIB",.T.)
			MIB->MIB_FILIAL := xFilial("MIB")
			MIB->MIB_CODBOM  := cCodBom
			MIB->MIB_NROLAC := oModelU01:GetValue('U01_LACREN')
			MIB->MIB_CORLAC := oModelU01:GetValue('U01_CORLAC')
			MIB->MIB_DATA   := oModelU00:GetValue('U00_DTINT')
			MIB->MIB_STATUS := "U" //usado
			MIB->(MsUnlock())
		Next _z
		oModelU01:Goline(1)

		If lGravaMIF
			//Grava registro na tabela padrão (MIF) utilizado pelo template posto matriz
			IncluiMIF(oModelU00,oModelU01,oModelU02)
		Endif
	Endif
Endif

Return xRet

Static Function ValBomba(cCodBom)

	Local _lRet := .T.
	Local cSGBD	:= AllTrim(Upper(TcGetDb()))

	If Select("QRYBOMBA") > 0
		QRYBOMBA->(DbCloseArea())
	Endif

	cQry := "SELECT MHY_CODBOM"
	cQry += " FROM "+RetSqlName("MHY")+""
	cQry += " WHERE D_E_L_E_T_ 	<> '*'"
	cQry += " AND MHY_CODBOM 	= '"+cCodBom+"'"
	cQry += " AND MHY_STATUS = '1' "//ativa

	cQry := ChangeQuery(cQry)
	TcQuery cQry NEW Alias "QRYBOMBA"

	If QRYBOMBA->(EOF())
		MsgInfo("Código da Bomba inválido ou Bomba Desativada!!","Atenção")

		_lRet := .F.
	Endif

	If _lRet

		cQry := "SELECT COUNT(*) TOTAL"
		cQry += " FROM "+RetSqlName("MID")+" MID"
		cQry += " INNER JOIN "+RetSqlName("MIC")+" MIC ON MIC.D_E_L_E_T_ = '' AND MIC.MIC_CODBIC = MID_CODBIC AND MIC.MIC_CODBOM = '"+cCodBom+"'"
		cQry += " WHERE MID.D_E_L_E_T_	= ''"
		cQry += " AND MID_FILIAL 		= '"+xFilial("MID")+"'"
		cQry += " AND MID.MID_AFERIR 	<> 'S' " //retira aferições
		If cSGBD $ 'POSTGRES|ORACLE'
			cQry += " AND LENGTH(MID_NUMORC) = 1 "
		Else
			cQry += " AND LEN(MID_NUMORC) 	= 1 "
		EndIf
		cQry += " AND MID_DATACO 		= '"+DToS(dDataBase)+"'"
		cQry += " AND MID_XDIVER 		<> '3'" //Abastecimento pendente e diferente de divergência a menor
		cQry += " AND ((MIC_STATUS = '1' AND MIC_XDTATI <= '"+DToS(dDataBase)+"') OR (MIC_STATUS = '2' AND MIC_XDTDES >= '"+DToS(dDataBase)+"'))"

		//MemoWrite("C:\TEMP\VALBOMBA.TXT",cQry)
		cQry := ChangeQuery(cQry)
		TcQuery cQry New alias "VALBOMBA"

		If VALBOMBA->TOTAL > 1
			Alert("Existem abastecimentos em aberto para essa bomba, operação não permitida!")
			_lRet:=.F.
		Endif

		VALBOMBA->(DbCloseArea())
	Endif

	If Select("QRYBOMBA") > 0
		QRYBOMBA->(DbCloseArea())
	Endif

Return _lRet

Static Function IncluiMIF(oModelU00,oModelU01,oModelU02)

	Local aArea			:= GetArea()
	Local nI, nJ
	Local nQtdLcr		:= 0

	DbSelectArea("MIF")

	For nJ := 1 to oModelU01:Length()
		oModelU01:Goline(nJ)
		If !Empty(oModelU01:GetValue("U01_LACREN"))
			nQtdLcr++
		Endif
	Next nJ
		
	RecLock("MIF",.T.)
	MIF->MIF_FILIAL := xFilial("MIF")
	MIF->MIF_CODMAN	:= oModelU00:GetValue("U00_NUMSEQ")
	MIF->MIF_TIPO	:= "2" //1=Implantação;2=Tecnica;3=Preventiva;4=Outros
	MIF->MIF_NUMINT := oModelU00:GetValue("U00_NUMINT")
	MIF->MIF_DTSUB	:= oModelU00:GetValue("U00_DTINT")
	MIF->MIF_HRSUB	:= oModelU00:GetValue("U00_HORAIN")
	MIF->MIF_MOTIVO := oModelU00:GetValue("U00_MOTINT")
	MIF->MIF_CNPJEM := oModelU00:GetValue("U00_CNPJFO")
	MIF->MIF_CPFTEC := oModelU00:GetValue("U00_CPFTEC")
	MIF->MIF_NOMTEC := oModelU00:GetValue("U00_NUMTEC")
	MIF->MIF_LACREM := nQtdLcr
	MIF->MIF_LACAPL := nQtdLcr
	MIF->(MsUnlock())

	//Atualizar tabela de itens Manutençao - MIB
	For nI := 1 to oModelU02:Length()
		oModelU02:Goline(nI)

		Reclock("MIB",.T.)
		MIB->MIB_FILIAL := xFilial("MIB")
		MIB->MIB_CODMAN := oModelU00:GetValue("U00_NUMSEQ")
		MIB->MIB_CODBOM := oModelU00:GetValue("U00_BOMBA")
		MIB->MIB_CODBIC := oModelU02:GetValue("U02_BICO")
		MIB->MIB_CODCON	:= Posicione("MIC",2,xFilial("MIC") + MIB->MIB_CODBOM + MIB->MIB_CODBIC, "MIC_XCONCE") //MIC_FILIAL+MIC_CODBOM+MIC_CODBIC
		MIB->MIB_NROLAC := oModelU01:GetValue('U01_LACREN')
		MIB->MIB_CORLAC := oModelU01:GetValue('U01_CORLAC')
		MIB->MIB_MOTIVO := oModelU00:GetValue("U00_MOTINT")
		MIB->MIB_DATA   := oModelU00:GetValue('U00_DTINT')
		MIB->MIB_STATUS := "U" //usado
		MIB->MIB_ENCINI := oModelU02:GetValue("U02_ENCANT")
		MIB->MIB_ENCFIM := oModelU02:GetValue("U02_ENCATU")
		MIB->(MsUnlock())

	Next nI

	RestArea(aArea)

Return
