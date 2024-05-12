#INCLUDE "TOTVS.CH"

Static aRet__Func := __FunArr()
Static aVetVazio  := {{Space(15),Space(5),Space(15),Space(4),Space(8),Space(4)}}

//-------------------------------------------------------------------
/*/{Protheus.doc} Run_Aplica
Funcoes genericas
@author  Carlos A. Gomes Jr.or
@since   11/08/04
@version P12
/*/
//-------------------------------------------------------------------
User Function Run_Aplica
	MsApp():New('SIGAESP')
	oApp:CreateEnv()
	oApp:Activate({||AuxRunAplica(.F.),Final()})

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} RunAplica
Executar programa via tela...

@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
User Function RunAplica

	Local oBar
	//Local cMenuBmp := GetMenuBmp()

	If Type("OMAINWND") != "O"

		//Variaveis para tela Principal
		Private oShortList, oMainWnd, oFont
		Private lLeft     := .F.
		Private cVersao   := GetVersao()
		Private dDataBase := MsDate()
		Private cUsuario  := "TOTVS"

		DEFINE FONT oFont NAME "MS Sans Serif" SIZE 0, -9

		DEFINE WINDOW oMainWnd FROM 0,0 TO 800, 600  TITLE  "Tela principal RunAplica."
		oMainWnd:oFont := oFont
		oMainWnd:SetColor(CLR_BLACK,CLR_WHITE)
		oMainWnd:Cargo := oShortList
		oMainWnd:oFont := oFont
		oMainWnd:nClrText := 0
		oMainWnd:lEscClose := .F.

		MainToolBar(@oBar)

		SET MESSAGE OF oMainWnd TO oEmToAnsi(cVersao)  NOINSET FONT oFont
		DEFINE MSGITEM oMsgItem0 OF oMainWnd:oMsgBar PROMPT '     '               SIZE 50
		DEFINE MSGITEM oMsgItem1 OF oMainWnd:oMsgBar PROMPT dDataBase             SIZE 100
		DEFINE MSGITEM oMsgItem2 OF oMainWnd:oMsgBar PROMPT Substr(cUsuario,1,6)  SIZE 100
		DEFINE MSGITEM oMsgItem3 OF oMainWnd:oMsgBar PROMPT 'Microsiga / Matriz'  SIZE 180
		DEFINE MSGITEM oMsgItem4 OF oMainWnd:oMsgBar PROMPT 'Ambiente'            SIZE 180

		oMainWnd:ReadClientCoors()

		ACTIVATE WINDOW oMainWnd MAXIMIZED ON INIT ( AuxRunAplica(.T.) , oMainWnd:End())

	Else
		AuxRunAplica(.F.)
	EndIf

Return

//DEFINICOES HTML
	#Define HTMO ' <B><font size="4"> '
	#Define HTMC ' </B></font> '

//-------------------------------------------------------------------
/*/{Protheus.doc} AuxRunAplica
Função para executar funcoes.
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function AuxRunAplica(lRunEnv)

	Local bGet,oDlgRun,oResult,cResult
	Local cGet      := Space(255)
	Local cEmpRun   := "99"
	Local cFilRun   := "01    "
	Local cUsuRun   := Padr("Admin",20," ")
	Local cPasRun   := Space(20)
	Local lComAmb   := .F.
	Local lProtErro := .F.
	Local cMascFun  := Space(80)
	Local nCount    := 0

	DEFAULT lRunEnv := .T.

	If !lRunEnv
		cEmpRun   := cEmpAnt
		cFilRun   := cFilAnt
		cUsuRun   := Substr(cUsuario,7,15)
	EndIf

	Private oList
	Private xRet     := Space(255)
	Private aListBox := AClone(aVetVazio)

	oDlgRun := MSDialog():New(0,0,600,600,"Executa função",,,,,,,,,.T.,,,)

	TSay():New(05,02, {|| "Empresa:" },oDlgRun,,,,,,.T.,,,30,10,,,,,,.T.)
	TGet():New(03,28, bSETGET(cEmpRun),oDlgRun,30,10,,,,,,,,.T.,,,{|| lRunEnv .And. !lComAmb },,,,,,)
	TSay():New(05,62, {|| "Filial:" },oDlgRun,,,,,,.T.,,,30,10,,,,,,.T.)
	TGet():New(03,85, bSETGET(cFilRun),oDlgRun,30,10,,,,,,,,.T.,,,{|| lRunEnv .And. !lComAmb },,,,,,)

	TSay():New(05,120, {|| "Usuario:" },oDlgRun,,,,,,.T.,,,30,10,,,,,,.T.)
	TGet():New(03,145, bSETGET(cUsuRun),oDlgRun,60,10,,,,,,,,.T.,,,{|| lRunEnv .And. !lComAmb },,,,,,)
	//TSay():New(05,185, {|| "Senha:" },oDlgRun,,,,,,.T.,,,30,10,,,,,,.T.)
	//TGet():New(03,205, bSETGET(cPasRun),oDlgRun,30,10,,,,,,,,.T.,,,{|| lRunEnv .And. !lComAmb },,,,,.T.,)

	TSay():New(40,02, {|| "Comando:" },oDlgRun,,,,,,.T.,,,30,10,,,,,,.T.)
	TGet():New(38,30, bSETGET(cGet),oDlgRun,210,10,,,,,,,,.T.,,,,,,,,,)
	TButton():New(18,02,"&Ambiente",oDlgRun,{|| AuxRunApl(cEmpRun,cFilRun,cUsuRun,cPasRun,,,,@lComAmb) },45,15,,,,.T.,,,,{|| lRunEnv .And. !lComAmb },,)
	TButton():New(18,52,"&Sem Ambiente",oDlgRun,{|| RpcClearEnv(),lComAmb := .F. },45,15,,,,.T.,,,,{|| lRunEnv .And. lComAmb },,)
	TButton():New(37,250,"&Executar",oDlgRun,{|| If(Empty(cGet),bGet:={|| .T. },bGet := &("{||xRet := "+cGet+" }")), MsgRun("Executando...","Aguarde.",{||TrataExec(bGet,lProtErro)}), cResult := VarInfo('xRet',xRet,,.F.), oResult:Refresh() },45,15,,,,.T.,,,,,,)
	TSay():New(60,02, {|| "Resultado:" },oDlgRun,,,,,,.T.,,,50,10,,,,,,.T.)
	TCheckBox():New(55,250,'Proteção erro', bSETGET(lProtErro), oDlgRun, 55, 10,,,,,,,,.T.,,,)
	oResult := TMultiGet():New(70,02,bSETGET(cResult),oDlgRun,293,090,,,,,,.T.,,,,,,,,,,,)

	TSay():New(164,02, {|| Repl("_",293) },oDlgRun,,,,,,.T.,,,293,10,,,,,,.T.)

	TSay():New(180,002, {|| "Máscara função:" },oDlgRun,,,,,,.T.,,,50,10,,,,,,.T.)
	TGet():New(178,050, bSETGET(cMascFun),oDlgRun,160,10,,,,,,,,.T.,,,,,,,,,)
	TGet():New(178,212, bSETGET(nCount),oDlgRun,25,10,,,,,,,,.T.,,,{|| .F. },,,,,,)
	TButton():New(177,250,"&Buscar",oDlgRun,{|| nCount := LeFuncRPO(cMascFun) },45,15,,,,.T.,,,,,,)
	oList := TWBrowse():New(195,002,293,080,,{"Função","Tipo","Arquivo","Linha","Data","Hora"},,oDlgRun,,,,,,,,,,,,.F.,,.T.,,.F.,,,)
	oList:SetArray(aListBox)
	oList:bLine := {|| aEval(aListBox[oList:nAt],{|z,w| aListBox[oList:nAt,w] } ) }
	oList:bLDblClick := { || cResult := BuscaPar(aListBox[oList:nAT,1],aListBox[oList:nAT,2] == "ADVPL"), oResult:Refresh() }
	TButton():New(280,250,"&Fechar",oDlgRun,{|| oDlgRun:End()},45,15,,,,.T.,,,,,,)

	oDlgRun:Activate(,,,.T.,,,)

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} AuxRunApl
Monta ambiente.
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function AuxRunApl(cEmpRun,cFilRun,cUsrRun,cPasRun,cModRun,cFunRun,cTabRun,lComAmb)

	Local oBkpObj

	DEFAULT cEmpRun := "99"
	DEFAULT cFilRun := "01"

	If Empty(cUsrRun)
		cUsrRun := Nil
	Else
		cUsrRun := AllTrim(cUsrRun)
	EndIf

	If Empty(cPasRun)
		cPasRun := Nil
	Else
		cPasRun := AllTrim(cPasRun)
	EndIf

	lComAmb := .T.

	oBkpObj := oMainWnd
	oMainWnd := Nil

	RpcSetType(2)
	MsgRun("Aguarde...","Montando Ambiente. Empresa ["+cEmpRun+"] Filial ["+cFilRun+"].",{|| RpcSetEnv( cEmpRun,cFilRun,cUsrRun,cPasRun,"TMS",/*FunName*/,/*{Tables}*/) } )

	If ( !Empty(cUsrRun) .Or. !Empty(cPasRun) )
		PswOrder(2)
		If ( !PswSeek(cUsrRun) .Or. !PswName(cPasRun) )
			MsgStop("Usuario ou senha invalidos.["+cUsrRun+"]","RunAplica")
			RpcClearEnv()
			lComAmb := .F.
		EndIf
	EndIf

	__cInternet := Nil
	oMainWnd := oBkpObj
	oBkpObj := Nil

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} TrataExec
Executa função tratando erro. 
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function TrataExec(bBloco,lProtErro)

	Local bErrBlock

	DEFAULT lProtErro := .F.

	If lProtErro
		bErrBlock := ErrorBlock()
		ErrorBlock( {|e| ExecErro(e) } )
	EndIf

	Begin Sequence
		EVAL(bBloco)
	End Sequence

	If lProtErro
		ErrorBlock( bErrBlock )
	EndIf

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} ExecErro
Novo tratamento de erro.
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function ExecErro(e)
	MsgStop(HTMO+"Existe um erro na função:"+HTMC+"<BR><BR>Verifique a ocorrência :<BR><BR>"+e:description, "ERRO")
	xRet := CRLF+e:description+CRLF
	Break
Return

//-------------------------------------------------------------------
/*/{Protheus.doc} LeFuncRPO
Le funcoes do RPO.
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function LeFuncRPO(cMascFun)
	Local aType,aFile,aLine,aDate,aTime
	Local aFuns    := {}
	Local nCount   := 0
	Local lComMask := .F.
	Local nFAdvpl  := 0

	cMascFun := AllTrim(cMascFun)
	If !Empty(cMascFun)
		// Buscar informacoes de todas as funcoes contidas no APO
		MsgRun("Buscando funções protheus.","Aguarde",{||aFuns := GetFuncArray(cMascFun, aType, aFile, aLine, aDate, aTime)})

		aListBox := {}

		For nCount := 1 To Len(aFuns)
			AAdd(aListBox, { aFuns[nCount], aType[nCount], aFile[nCount], aLine[nCount], aDate[nCount], aTime[nCount]} )
		Next

		lComMask := ( At("*",cMascFun) > 0 )

		cMascFun := StrTran(cMascFun,"*","")
		cMascFun := Upper(AllTrim(cMascFun))

		If lComMask
			AEval(aRet__Func,{|x,y| If(Empty(cMascFun) .Or. cMascFun $ Upper(x[1]),( AAdd(aListBox, { x[1], "ADVPL", "", "", "", ""} ), nFAdvpl++ ),) })
		ElseIf ( nCount := AScan(aRet__Func,{|x| cMascFun $ Upper(x[1])  }) ) > 0
			AAdd(aListBox, { aRet__Func[nCount][1], "ADVPL", "", "", "", ""} )
			nFAdvpl++
		EndIf

	EndIf

	If Len(aListBox) == 0
		aListBox := AClone(aVetVazio)
	EndIf
	oList:SetArray(aListBox)
	oList:bLine := {|| aEval(aListBox[oList:nAt],{|z,w| aListBox[oList:nAt,w] } ) }
	oList:Refresh()

Return Len(aFuns)+nFAdvpl

/*/{Protheus.doc} BuscaPar
Busca parametros de uma função específica.

@author Carlos Alberto Gomes Junior
@since 13/02/2014
@version 1.0
@param cNomeFunc, character, Nome da função
@param lAdvpl, logico, Se a função é do Protheus ou do Advpl
@return cRetPar, Descrição dos parametros da função
/*/
Static Function BuscaPar(cNomeFunc,lAdvpl)

	Local cRet      := ""
	Local cRetPar   := ""
	Local cPar      := ""
	Local nCount    := 0
	Local nCount2   := 0
	Local aRet2     := {}
	Local cChamaFun := cNomeFunc+"("

	If lAdvpl
		nCount := ascan(aRet__Func,{|x|cNomeFunc $ x[1]})
		If nCount>0
			For nCount2 := 1 to len(aRet__Func[nCount][2]) step 2
				cPar := SubStr(aRet__Func[nCount][2],nCount2,2)
				Do Case
				Case Left(cPar,1)=='*'
					cRet := 'xExp'+strZero((nCount2+1)/2,2)+' - variavel'
				Case Left(cPar,1)=='C'
					cRet := 'cExp'+strZero((nCount2+1)/2,2)+' - caracter'
				Case Left(cPar,1)=='N'
					cRet:='nExp'+strZero((nCount2+1)/2,2)+' - numerico'
				Case Left(cPar,1)=='A'
					cRet:='aExp'+strZero((nCount2+1)/2,2)+' - array'
				Case Left(cPar,1)=='L'
					cRet:='lExp'+strZero((nCount2+1)/2,2)+' - logico'
				Case Left(cPar,1)=='B'
					cRet:='bExp'+strZero((nCount2+1)/2,2)+' - bloco de codigo'
				Case Left(cPar,1)=='O'
					cRet:='oExp'+strZero((nCount2+1)/2,2)+' - objeto'
				EndCase
				If Right(cPar,1)=='R'
					cRet+=' [obrigatorio]'
				ElseIf Right(cPar,1)=='O'
					cRet+=' [opcional]'
				EndIf
				cRetPar += "    Parametro " + cValtoChar((nCount2+1)/2) + "= " + cRet + CRLF
				cChamaFun += Left(cRet,6)+","
			Next nCount2
		EndIf
	Else
		aRet2:= GetFuncPrm(cNomeFunc)

		for nCount2:= 1 to Len(aRet2)
			cPar:= aRet2[nCount2]
			Do Case
			Case Left(cPar,1)=='X'
				cRet:=' - variavel'
			Case Left(cPar,1)=='C'
				cRet:=' - caracter'
			Case Left(cPar,1)=='N'
				cRet:=' - numerico'
			Case Left(cPar,1)=='A'
				cRet:=' - array'
			Case Left(cPar,1)=='L'
				cRet:=' - logico'
			Case Left(cPar,1)=='B'
				cRet:=' - bloco de codigo'
			Case Left(cPar,1)=='O'
				cRet:=' - objeto'
			OtherWise
				cRet:=' - Unknown'
			EndCase
			cRetPar += "    Parametro " + cValtoChar(nCount2) + "= " + aRet2[nCount2]+cRet + CRLF
			cChamaFun += aRet2[nCount2]+","
		Next
	EndIf
	cRetPar := Substr(cChamaFun,1,Len(cChamaFun)-1) + ")" + CRLF + cRetPar
Return cRetPar

//-------------------------------------------------------------------
/*/{Protheus.doc} UFExplor
File Explorer em ADVPL. Facilita manipulacao de arquivos no protheus.

@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
User Function UFExplor()

	Local oDlgExpl,oList01,oGet1,oGet2
	Local oBmp01, oBmp02

	Local cPatch01 := PadR("C:\",60)
	Local cPatch02 := PadR("\",60)

	Static oFolder  := LoadBitmap( GetResources(), "FOLDER5")
	Static oFile    := LoadBitmap( GetResources(), "RPMNEW2")
	Static cMaskArq := "*.*"

	Private oMainWnd

	DEFINE MSDIALOG oDlgExpl TITLE "Explorer." FROM 0,0 TO 600,800 PIXEL
	oMainWnd := oDlgExpl

	@ 002,002 MSGET oGet1 VAR cPatch01 PICTURE "@!" PIXEL SIZE 150,009 WHEN .F.
	@ 003,160 BITMAP oBmp01 NAME "OPEN"      SIZE 015,015 OF oDlgExpl PIXEL NOBORDER ON CLICK ( cPatch01 := OpenBtn(cPatch01,"T") , LeDirect(@oList01,@oGet1,@cPatch01) )
	@ 220,002 BITMAP oBmp01 NAME "BMPDEL"    SIZE 015,015 OF oDlgExpl PIXEL NOBORDER ON CLICK MsgRun("Apagando Arquivo...","Aguarde.",{|| FApaga(cPatch01,oList01) , LeDirect(@oList01,@oGet1,@cPatch01) })
	@ 220,017 BITMAP oBmp01 NAME "SDUDRPTBL" SIZE 015,015 OF oDlgExpl PIXEL NOBORDER ON CLICK Processa({|| FApaga(cPatch01,oList01,.T.), LeDirect(@oList01,@oGet1,@cPatch01) },"Exclusão de arquivos","Excluindo",.T.)

	@ 002,220 MSGET oGet2 VAR cPatch02 PICTURE "@!" PIXEL SIZE 150,009 WHEN .F.
	@ 003,380 BITMAP oBmp02 NAME "OPEN"      SIZE 015,015 OF oDlgExpl PIXEL NOBORDER ON CLICK ( cPatch02 := OpenBtn(cPatch02,"S") , LeDirect(@oList02,@oGet2,@cPatch02) )
	@ 220,220 BITMAP oBmp01 NAME "BMPDEL"    SIZE 015,015 OF oDlgExpl PIXEL NOBORDER ON CLICK MsgRun("Apagando Arquivo...","Aguarde.",{|| FApaga(cPatch02,oList02) , LeDirect(@oList02,@oGet2,@cPatch02) })
	@ 220,235 BITMAP oBmp01 NAME "SDUDRPTBL" SIZE 015,015 OF oDlgExpl PIXEL NOBORDER ON CLICK Processa({|| FApaga(cPatch02,oList02,.T.), LeDirect(@oList02,@oGet2,@cPatch02) },"Exclusão de arquivos","Excluindo",.T.)

	@ 025,195 BITMAP oBmp01 NAME "RIGHT"   SIZE 015,015 OF oDlgExpl PIXEL NOBORDER ON CLICK MsgRun("Copiando Arquivo...","Aguarde.",{|| FCopia(cPatch01,cPatch02,oList01) , LeDirect(@oList01,@oGet1,@cPatch01),  LeDirect(@oList02,@oGet2,@cPatch02) })
	@ 045,195 BITMAP oBmp01 NAME "LEFT"    SIZE 015,015 OF oDlgExpl PIXEL NOBORDER ON CLICK MsgRun("Copiando Arquivo...","Aguarde.",{|| FCopia(cPatch02,cPatch01,oList02) , LeDirect(@oList01,@oGet1,@cPatch01),  LeDirect(@oList02,@oGet2,@cPatch02) })
	@ 065,195 BITMAP oBmp01 NAME "RIGHT_2" SIZE 015,015 OF oDlgExpl PIXEL NOBORDER ON CLICK Processa({|| FCopia(cPatch01,cPatch02,oList01,.T.), LeDirect(@oList01,@oGet1,@cPatch01), LeDirect(@oList02,@oGet2,@cPatch02) },"Copia de arquivos","Copiando",.T.)
	@ 085,195 BITMAP oBmp01 NAME "LEFT2"   SIZE 015,015 OF oDlgExpl PIXEL NOBORDER ON CLICK Processa({|| FCopia(cPatch02,cPatch01,oList02,.T.), LeDirect(@oList01,@oGet1,@cPatch01), LeDirect(@oList02,@oGet2,@cPatch02) },"Copia de arquivos","Copiando",.T.)
	@ 105,195 BITMAP oBmp01 NAME "FILTRO"  SIZE 015,015 OF oDlgExpl PIXEL NOBORDER ON CLICK ( MaskDir() , LeDirect(@oList01,@oGet1,@cPatch01), LeDirect(@oList02,@oGet2,@cPatch02) )

	@ 015,002 LISTBOX oList01 FIELDS HEADER " "," " SIZE 180,200 OF oDlgExpl PIXEL COLSIZES 05,40 ON DBLCLICK LeDirect(@oList01,@oGet1,@cPatch01,.T.)
	@ 015,220 LISTBOX oList02 FIELDS HEADER " "," " SIZE 180,200 OF oDlgExpl PIXEL COLSIZES 05,40 ON DBLCLICK LeDirect(@oList02,@oGet2,@cPatch02,.T.)
	LeDirect(@oList01,@oGet1,@cPatch01)
	LeDirect(@oList02,@oGet2,@cPatch02)

	ACTIVATE MSDIALOG oDlgExpl CENTERED

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} LeDirect
Funcao auxiliar leitura de diretorios no FExplorer.
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function LeDirect(oObjList,oGetInfo,cInfoPatch,lClick)

	Local aRetList := {{"0",".."}}
	Local aArqInfo := {}

	DEFAULT lClick := .F.

	cInfoPatch := AllTrim(cInfoPatch)

	If lClick
		If oObjList:aArray[oObjList:nAt][1] == "0"
			cInfoPatch := Substr(cInfoPatch,1,RAT("\",Substr(cInfoPatch,1,Len(cInfoPatch)-1)))
		ElseIf oObjList:aArray[oObjList:nAt][1] == "1"
			cInfoPatch := cInfoPatch+AllTrim(oObjList:aArray[oObjList:nAt][2])+"\"
		Else
			Return
		EndIf
	EndIf

	aArqInfo := Directory(cInfoPatch+cMaskArq,"D")

	If Len(aArqInfo) > 0
		AEval(aArqInfo,{|x,y| If(Left(AllTrim(x[1]),1)!=".",AAdd(aRetList,{Iif("D"$x[5],"1","2"),x[1]}),) })
		ASort(aRetList,,,{|x,y| x[1]+x[2] < y[1]+y[2] })
	EndIf

	oObjList:SetArray(aRetList)
	oObjList:bLine := { || {Iif(aRetList[oObjList:nAt][1] == "2",oFile,oFolder),aRetList[oObjList:nAt][2]}}
	oObjList:nAt := 1
	oObjList:Refresh()
	oGetInfo:Refresh()

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} OpenBtn
Funcao auxiliar botao de discos no FExplorer.
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function OpenBtn(cAtual,cOnde)
	Local cRetDir := ""
	If cOnde == "T"
		cRetDir := cGetFile("Todos Arquivos|*.*|","Escolha o caminho dos arquivos.",0,cAtual,,GETF_RETDIRECTORY+GETF_LOCALHARD+GETF_LOCALFLOPPY+GETF_NETWORKDRIVE)
	ElseIf cOnde == "S"
		cRetDir := cGetFile("Todos Arquivos|*.*|","Escolha o caminho dos arquivos.",0,cAtual,,GETF_RETDIRECTORY+GETF_ONLYSERVER)
	EndIf
	cRetDir := Iif(Empty(cRetDir),cAtual,cRetDir)
Return cRetDir

//-------------------------------------------------------------------
/*/{Protheus.doc} FCopia
Funcao auxiliar de copia no FExplorer.
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function FCopia(cPatchOri,cPatchDes,oObjList,lMultCpy)
	Local aMultCopy := {}
	Private lAbortPrint := .F.

	DEFAULT lMultCpy := .F.

	If lMultCpy
		AEval(oObjList:aArray,{|x,y| If(x[1] == "2",AAdd(aMultCopy,AllTrim(x[2])),) })
		ProcRegua(Len(aMultCopy))
		If ":" $ cPatchOri
			AEval(aMultCopy,{|x,y| If(!lAbortPrint, (CPYT2S(cPatchOri+x,cPatchDes,.T.), IncProc("Copiando "+Transform(y*100/Len(aMultCopy),"@E 99")+"% - "+x) ),) })
		Else
			AEval(aMultCopy,{|x,y| If(!lAbortPrint, (CPYS2T(cPatchOri+x,cPatchDes,.T.), IncProc("Copiando "+Transform(y*100/Len(aMultCopy),"@E 99")+"% - "+x) ),) })
		EndIf
	ElseIf oObjList:aArray[oObjList:nAt][1] == "2"
		If ":" $ cPatchOri
			If !CPYT2S(cPatchOri+oObjList:aArray[oObjList:nAt][2],cPatchDes,.T.)
				MsgAlert("Erro ao copiar arquivo.","Atenção")
			EndIf
		Else
			If !CPYS2T(cPatchOri+oObjList:aArray[oObjList:nAt][2],cPatchDes,.T.)
				MsgAlert("Erro ao copiar arquivo.","Atenção")
			EndIf
		EndIf
	Else
		MsgAlert("Não copia pastas.","Atenção")
	EndIf
Return

//-------------------------------------------------------------------
/*/{Protheus.doc} FApaga
Funcao auxiliar de Mascara de Filtro no FExplorer.
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function FApaga(cPatchOri,oObjList,lEraseMult)

	Local aMultErase := {}
	Local cEraseFile := AllTrim(oObjList:aArray[oObjList:nAt][2])

	Private lAbortPrint := .F.

	DEFAULT lEraseMult := .F.

	If lEraseMult
		AEval(oObjList:aArray,{|x,y| If(x[1] == "2",AAdd(aMultErase,AllTrim(x[2])),) })
		ProcRegua(Len(aMultErase))
		If MsgNoYes("Confirma a exclusao de "+AllTrim(Str(Len(aMultErase)))+" arquivos?","Atenção")
			AEval(aMultErase,{|x,y| If(!lAbortPrint, (FErase(AllTrim(cPatchOri)+x), IncProc("Apagando "+Transform(y*100/Len(aMultErase),"@E 99")+"% - "+x) ),) })
		EndIf
	ElseIf oObjList:aArray[oObjList:nAt][1] == "2"
		If MsgNoYes("Apagar o arquivo ["+cEraseFile+"]?","Atenção")
			FErase(AllTrim(cPatchOri)+cEraseFile)
		EndIf
	Else
		MsgAlert("Não apaga pastas.","Atenção")
	EndIf

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} MaskDir
Funcao auxiliar de delete no FExplorer. 
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function MaskDir

	Local oDlMask,oGetMask

	cMaskArq := Padr(cMaskArq,60)

	DEFINE MSDIALOG oDlMask TITLE "Informe a mascara de arquivos." FROM 0,0 TO 30,230 PIXEL
	@ 02,02 MSGET oGetMask VAR cMaskArq PICTURE "@!" PIXEL SIZE 70,009 VALID Len(AllTrim(cMaskArq)) >= 3 .And. "." $ cMaskArq
	@ 02,75 BUTTON "Ok" SIZE 037,012 PIXEL OF oDlMask Action oDlMask:End()
	ACTIVATE MSDIALOG oDlMask CENTERED VALID Len(AllTrim(cMaskArq)) >= 3 .And. "." $ cMaskArq

	cMaskArq := AllTrim(cMaskArq)

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} UFuncPrm
Função de busca de funções e parametros. Será exibido no console do server.
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
User Function UFuncPrm(cNomeFunc,lExact)
	Local aRet
	Local aRet2
	Local nCount// Para retornar a origem da função: FULL, USER, PARTNER, PATCH, TEMPLATE ou NONE
	Local nCount2// Para retornar a origem da função: FULL, USER, PARTNER, PATCH, TEMPLATE ou NONE
	Local aType // Para retornar o nome do arquivo onde foi declarada a função
	Local aFile// Para retornar o número da linha no arquivo onde foi declarada a função
	Local aLine// Para retornar a data do código fonte compilado
	Local aDate// Para retornar a hora do código fonte compilado
	Local aTime
	Local cRet := ''
	Local lRet := .T.
	Local cOper:= '*'
	Local cPar := ''

	Default lExact := .F.

	If lExact
		cOper:=''
	EndIf

	// Buscar informações de todas as funções contidas no APO
	// tal que tenham a substring 'test' em algum lugar de seu nome
	If !empty(aRet := GetFuncArray(cOper+cNomeFunc+cOper, aType, aFile, aLine, aDate,aTime))

//		for nCount := 1 To Len(aRet)
		nCount:= ascan(aRet,{|x|cNomeFunc$x[1]})//localizar só a primeira ocorrência
		//conout(t("Funcao do Protheus " + cValtoChar(nCount) + "= " + aRet[nCount])
		//conout(t("Arquivo " + cValtoChar(nCount) + "= " + aFile[nCount])

		//conout(t("Linha " + cValtoChar(nCount) + "= " + aLine[nCount])
		//conout(t("Tipo " + cValtoChar(nCount) + "= " + aType[nCount])

		//conout(t("Data " + cValtoChar(nCount) + "= " + DtoC(aDate[nCount]))
		//conout(t("Hora " + cValtoChar(nCount) + "= " + aTime[nCount])

		aRet2:= GetFuncPrm(aRet[nCount])

		for nCount2:= 1 to Len(aRet2)
			cPar:= aRet2[nCount2]
			Do Case
			Case Left(cPar,1)=='*'
				cRet:=' - variavel'
			Case Left(cPar,1)=='C'
				cRet:=' - caracter'
			Case Left(cPar,1)=='N'
				cRet:=' - numerico'
			Case Left(cPar,1)=='A'
				cRet:=' - array'
			Case Left(cPar,1)=='L'
				cRet:=' - logico'
			Case Left(cPar,1)=='B'
				cRet:=' - bloco de codigo'
			Case Left(cPar,1)=='O'
				cRet:=' - objeto'
			EndCase
			cRet:= "    Parametro " + cValtoChar(nCount2) + "= " + aRet2[nCount2]+cRet
			//conout(t(cRet)
		next
//		Next
	Else
		aRet:= __FunArr()

		nCount:= ascan(aRet,{|x|cNomeFunc$x[1]})
		If nCount>0
			//conout(t("Funcao Interna = " + aRet[nCount][1])
			////conout(t("Parametros "+ aRet[nCount][2])
			For nCount2:= 1 to len(aRet[nCount][2]) step 2
				cPar:=SubStr(aRet[nCount][2],nCount2,2)
				Do Case
				Case Left(cPar,1)=='*'
					cRet:='xExp'+strZero((nCount2+1)/2,2)+' - variavel'
				Case Left(cPar,1)=='C'
					cRet:='cExp'+strZero((nCount2+1)/2,2)+' - caracter'
				Case Left(cPar,1)=='N'
					cRet:='nExp'+strZero((nCount2+1)/2,2)+' - numerico'
				Case Left(cPar,1)=='A'
					cRet:='aExp'+strZero((nCount2+1)/2,2)+' - array'
				Case Left(cPar,1)=='L'
					cRet:='lExp'+strZero((nCount2+1)/2,2)+' - logico'
				Case Left(cPar,1)=='B'
					cRet:='bExp'+strZero((nCount2+1)/2,2)+' - bloco de codigo'
				Case Left(cPar,1)=='O'
					cRet:='oExp'+strZero((nCount2+1)/2,2)+' - objeto'
				EndCase
				If Right(cPar,1)=='R'
					cRet+=' [obrigatorio]'
				ElseIf Right(cPar,1)=='O'
					cRet+=' [opcional]'
				EndIf
				cRet:="    Parametro " + cValtoChar((nCount2+1)/2) + "= " + cRet
				//conout(t(cRet)
			Next nCount2

		Else
			//conout(t("Nome de função invalida")
			lRet:=.F.
		EndIf
	EndIf

Return lRet


