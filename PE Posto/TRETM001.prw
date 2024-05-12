#INCLUDE "PROTHEUS.CH"
#INCLUDE "PARMTYPE.CH"
#INCLUDE "TOTVS.CH"
#INCLUDE "TBICONN.CH"
#INCLUDE "XMLXFUN.CH"
#INCLUDE "TOPCONN.CH"
#Include "SIGAWIN.CH"

/*/{Protheus.doc} TRETM001 (LOJA070)
Pontos de entrada MVC do cadastro de Adm Financeira.

@author Danilo
@since 08/10/2018
@version 1.0
@type function
/*/
User Function TRETM001()

	Local aParam     := PARAMIXB
	Local xRet       := .T.
	Local oObj       := ''
	Local cIdPonto   := ''
	Local cIdModel   := ''
	Local lIsGrid    := .F.
	Local lMvRepSAE  := SuperGetMv("MV_XREPSAE",,.T.) //parametro que habilita ou nao replicar cadastro ADM Fin.
	Local nOperation

	If aParam <> NIL

		oObj       := aParam[1]
		cIdPonto   := aParam[2]
		cIdModel   := aParam[3]
		lIsGrid    := ( Len( aParam ) > 3 )
		nOperation := oObj:GetOperation()

		If cIdPonto == 'MODELCOMMITNTTS'
			If lMvRepSAE .AND. oObj:GetOperation() == 3 //inclusão
				LjMsgRun("Aguarde... Replicando para outras filiais...",,{|| ReplicaSAE() })
			EndIf
		ElseIf cIdPonto == 'BUTTONBAR'
			xRet := { }
			aadd(xRet, {'Cria Cliente', 'MSDOC', {|| U_TRETM01B() }, 'Cria Cliente' })
			aadd(xRet, {'Replicar', 'MSDOC', {|| U_TRETM01A() }, 'Replicar' }) //replicar 1 a 1
		EndIf

	EndIf

Return(xRet)


/*/{Protheus.doc} ReplicaSAE
Processa a replicação de cadastros para as demais filiais

@author Danilo
@since 08/10/2018
@version 1.0
@type function
/*/
Static Function ReplicaSAE(aListSM0)

	Local aArea		:= GetArea()
	Local cBkpFil 	:= cFilAnt
	Local aCampos	:= {}
	Local aCpoMEN	:= {}
	Local aLinha	:= {}
	Local cAE_COD	:= SAE->AE_COD
	Local aFiliais	:= {}
	Local nRecSAE	:= SAE->(Recno())
	Local nX, aSX3SAE, aSX3MEN
	Local cRelCOD := ""
	Local nPosCOD := 0
	Local nPosDES := 0
	Local lOk := .T.
	Local nOpAviso := 0

	Default aListSM0 := {}

	//montando campos cabecalho SAE
	aSX3SAE := FWSX3Util():GetAllFields( "SAE" , .F./*lVirtual*/ )
	If !empty(aSX3SAE)
		For nX := 1 to len(aSX3SAE)
			If X3Uso(GetSx3Cache(aSX3SAE[nX],"X3_USADO")) .AND. !(AllTrim(aSX3SAE[nX])$"AE_FILIAL") //.and. GetSx3Cache(aSX3SAE[nX],"X3_VISUAL") <> "V"
				aAdd( aCampos, { aSX3SAE[nX], SAE->&(aSX3SAE[nX]) } )
			EndIf
			If AllTrim(aSX3SAE[nX]) == "AE_COD"
				//Comentado pois esta bugando quando usa GetSXENum
				//cRelCOD := AllTrim(GetSx3Cache(aSX3SAE[nX],"X3_RELACAO"))
			EndIf
		next nX
	endif

	//montando campos tabela MEN (grid)
	aSX3MEN := FWSX3Util():GetAllFields( "MEN" , .F./*lVirtual*/ )
	DbSelectArea("MEN")
	MEN->(DbSetOrder(2))
	MEN->(DbSeek(xFilial("MEN")+SAE->AE_COD ))
	While MEN->(!Eof()) .AND. MEN->MEN_FILIAL+MEN->MEN_CODADM == xFilial("MEN")+SAE->AE_COD
		aLinha := {}
		For nX := 1 to len(aSX3MEN)
			If X3Uso(GetSx3Cache(aSX3MEN[nX],"X3_USADO")) .AND. !(aSX3MEN[nX]$"MEN_FILIAL")
				aAdd( aLinha, { aSX3MEN[nX], MEN->&(aSX3MEN[nX]) } )
			EndIf
		next nX
		aadd(aCpoMEN,aLinha)
		MEN->(DbSkip())
	Enddo

	//pegando as filiais que vão receber a ADM Fin
	If Empty(Select("SM0"))
		OpenSM0(cEmpAnt)
	EndIf
	SM0->(dbSetOrder(1)) // CÓDIGO + Cod. Filial
	SM0->(DbGoTop())
	SM0->(DbSeek(cEmpAnt))
	If Len(aListSM0) > 0
		For nX:=1 to Len(aListSM0)
			If SM0->(DbSeek(cEmpAnt+aListSM0[nX][1]))
				aadd(aFiliais, Alltrim(SM0->M0_CODFIL))
			EndIf
		Next
	Else
		While SM0->(!EOF()) .And. AllTrim(SM0->M0_CODIGO) == cEmpAnt
			If Alltrim(SM0->M0_CODFIL) <> Alltrim(cBkpFil) //senao for a mesma filial
				aadd(aFiliais, Alltrim(SM0->M0_CODFIL) )
			Endif
			SM0->(DbSkip())
		EndDo
	EndIf

	If !Empty(cRelCOD)
		SAE->(DbSetOrder(3)) //AE_FILIAL+AE_DESC+AE_COD
		nPosCOD := aScan(aCampos, {|x| alltrim(x[1]) == "AE_COD"})
		nPosDES := aScan(aCampos, {|x| alltrim(x[1]) == "AE_DESC"})
	Else
		SAE->(DbSetOrder(1)) //AE_FILIAL+AE_COD
	EndIf

	For nX := 1 to len(aFiliais)
		cFilAnt := aFiliais[nX]
		If !Empty(cRelCOD)
			aCampos[nPosCOD][2] := &(cRelCOD)
			lOk := .T.
			If SAE->(DbSeek(xFilial("SAE")+aCampos[nPosDES][2]))
				nOpAviso := Aviso("Atenção","Já existe uma administradora com essa descrição '"+AllTrim(aCampos[nPosDES][2])+"' na filial '"+cFilAnt+"', deseja continuar?",{"Sim","Não","Cancelar"})
				If nOpAviso == 2 //selecionou não, irá pular a replicação para essa filial
					lOk := .F.
				ElseIf nOpAviso == 3 //selecionou cancelar a operação, aborta a replicação
					Exit //sai do For nX
				EndIf
			EndIf
		EndIf
		If (!Empty(cRelCOD) .and. lOk) .or. (Empty(cRelCOD) .and. !SAE->(DbSeek(xFilial("SAE")+cAE_COD)))
			ExeIncSAE(aCampos, aCpoMEN) //faz a inclusao via execauto
		EndIf
	Next nX

	SAE->(DbSetORder(1))
	SAE->(DbGoTo(nRecSAE))

	cFilAnt := cBkpFil

	RestArea(aArea)

Return

/*/{Protheus.doc} ExeIncSAE
Execução da rotina de gravaçao
Foi tirado de execauto MVC pois quando colca itens estava dando erros.

@author Danilo
@since 08/10/2018
@version 1.0
@type function
@param aCampos, campos cabeçalho
@param aCpoMEN, campos itens
/*/
Static Function ExeIncSAE(aCampos, aCpoMEN)

	Local nI, nJ

	//gravando cabeçalho
	Reclock("SAE", .T.) //inclui
	SAE->AE_FILIAL := xFilial("SAE")
	For nI := 1 to len(aCampos)
		SAE->&(aCampos[nI][1]) := aCampos[nI][2]
	next nI
	SAE->(MsUnlock())

	//gravando itens
	for nI := 1 to len(aCpoMEN)
		Reclock("MEN", .T.) //inclui
		MEN->MEN_FILIAL := xFilial("MEN")
		For nJ := 1 to len(aCpoMEN[nI])
			MEN->&(aCpoMEN[nI][nJ][1]) := aCpoMEN[nI][nJ][2]
		next nJ
		MEN->(MsUnlock())
	next nI

Return

/*/{Protheus.doc} TRETM01A
Função que chama tela de seleção de filiais e replica apenas para algumas filiais.

@type function
@author Pablo Nunes
@since 24/07/2023
/*/
User Function TRETM01A()
	Local aMarcadas := {}

	If ALTERA .or. INCLUI //não esta em Visualizar
		MSGALERT( "Opção disponível apenas na visualização.", "Atenção" )
		Return
	EndIf

	aMarcadas := EscEmpresa(cEmpAnt,SAE->AE_FILIAL)

	If Len(aMarcadas)>0
		fwMsgRun(Nil, {|| ReplicaSAE(aMarcadas)}, "Aguarde", "Replicando para outras filiais...")
	EndIf

Return

/*/{Protheus.doc} TRETM01B
Chama a rotina de inclusão de cliente, quando não esta incluindo uma nova administradora financeira.

@type function
@author Pablo Nunes
@since 24/07/2023
/*/
User Function TRETM01B()

	If INCLUI
		MSGALERT( "Opção não disponível na inclusão.", "Atenção" )
		Return
	EndIf

	If !INCLUI //oObj:GetOperation() == 4 -> "Alterar"
		L070IncSA1(.F./*lMvc*/)
	EndIf

Return

/*/{Protheus.doc} EscEmpresa
Funcao Generica para escolha de Empresa, montado pelo SM0.
Retorna vetor contendo as selecoes feitas.
Se nao For marcada nenhuma o vetor volta vazio.

@author Totvs TBC
@since 31/10/2017

@version 1.0
@return ${return}, ${return_description}

@type function
/*/
Static Function EscEmpresa(cEmpEsc,cFilNot)
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Parametro  nTipo                           ³
//³ 1  - Monta com Todas Empresas/Filiais      ³
//³ 2  - Monta so com Empresas                 ³
//³ 3  - Monta so com Filiais de uma Empresa   ³
//³                                            ³
//³                                            ³
//³ Parametro  cEmpSel                         ³
//³ Empresa que sera usada para montar selecao ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	Local   aSalvAmb := GetArea()
	Local   aSalvSM0 := {}
	Local   aRet     := {}
	Local   aVetor   := {}
	Local   oDlg     := NIL
	Local   oChkMar  := NIL
	Local   oLbx     := NIL
	Local   oMascEmp := NIL
	Local   oButMarc := NIL
	Local   oButDMar := NIL
	Local   oButInv  := NIL
	Local   oSay     := NIL
	Local   oOk      := LoadBitmap( GetResources(), "LBOK" )
	Local   oNo      := LoadBitmap( GetResources(), "LBNO" )
	Local   lChk     := .F.
	Local   lTeveMarc:= .F.
	Local   cVar     := ""
	Local   cMascEmp := "??"
	Local   cMascFil := "??"
	Local   aMarcadas := {}

	Default cEmpEsc := ""
	Default cFilNot := ""

	If !MyOpenSm0(.T.)
		Return aRet
	EndIf

	dbSelectArea( "SM0" )
	aSalvSM0 := SM0->( GetArea() )
	dbSetOrder( 1 )
	dbGoTop()

	While !SM0->( EOF() )
		If (AllTrim(cFilNot) <> AllTrim(SM0->M0_CODFIL)) .and. (Empty(cEmpEsc) .or. AllTrim(SM0->M0_CODIGO) == AllTrim(cEmpEsc))
			If aScan( aVetor, {|x| x[2] == SM0->M0_CODIGO .and. x[3] == SM0->M0_CODFIL} ) == 0
				If Empty(cEmpEsc)
					aAdd( aVetor, { aScan( aMarcadas, {|x| x[1] == SM0->M0_CODIGO .and. x[2] == SM0->M0_CODFIL} ) > 0, SM0->M0_CODIGO, SM0->M0_CODFIL, SM0->M0_NOME, SM0->M0_FILIAL } )
				Else
					aAdd( aVetor, { aScan( aMarcadas, {|x| x[1] == SM0->M0_CODIGO .and. x[2] == SM0->M0_CODFIL} ) > 0, SM0->M0_CODFIL, SM0->M0_FILIAL } )
				EndIf
			EndIf
		EndIf
		SM0->( DbSkip() )
	EndDo

	RestArea( aSalvSM0 )

	Define MSDialog  oDlg Title "" From 0, 0 To 275, 396 Pixel

	oDlg:cToolTip := "Tela para Múltiplas Seleções de Empresas/Filiais"
	oDlg:cTitle   := "Selecione a(s) Empresa(s)..."

	If Empty(cEmpEsc)
		@ 10, 10 Listbox  oLbx Var  cVar Fields Header " ", "Empresa", "Filial", "Grupo", "Nome" Size 178, 095 Of oDlg Pixel
		oLbx:SetArray( aVetor )
		oLbx:bLine := {|| {IIf( aVetor[oLbx:nAt, 1], oOk, oNo ), ;
			aVetor[oLbx:nAt, 2], ;
			aVetor[oLbx:nAt, 3], ;
			aVetor[oLbx:nAt, 4], ;
			aVetor[oLbx:nAt, 5]}}
	Else
		@ 10, 10 Listbox  oLbx Var  cVar Fields Header " ", "Filial", "Nome" Size 178, 095 Of oDlg Pixel
		oLbx:SetArray( aVetor )
		oLbx:bLine := {|| {IIf( aVetor[oLbx:nAt, 1], oOk, oNo ), ;
			aVetor[oLbx:nAt, 2], ;
			aVetor[oLbx:nAt, 3]}}
	EndIf

	oLbx:BlDblClick := { || aVetor[oLbx:nAt, 1] := !aVetor[oLbx:nAt, 1], VerTodos( aVetor, @lChk, oChkMar ), oChkMar:Refresh(), oLbx:Refresh()}
	oLbx:cToolTip   :=  oDlg:cTitle
	oLbx:lHScroll   := .F. // NoScroll

	@ 112, 10 CheckBox oChkMar Var  lChk Prompt "Todos"   Message  Size 40, 007 Pixel Of oDlg;
		on Click MarcaTodos( lChk, @aVetor, oLbx )

	@ 124, 10 Button oButInv Prompt "&Inverter"  Size 32, 12 Pixel Action ( InvSelecao( @aVetor, oLbx ), VerTodos( aVetor, @lChk, oChkMar ) ) ;
		Message "Inverter Seleção" Of oDlg

// Marca/Desmarca por mascara
	@ 113, 51 Say  oSay Prompt "Empresa" Size  40, 08 Of oDlg Pixel
	@ 112, 80 MSGet  oMascEmp Var  cMascEmp Size  05, 05 Pixel Picture "@!"  Valid (  cMascEmp := StrTran( cMascEmp, " ", "?" ), cMascFil := StrTran( cMascFil, " ", "?" ), oMascEmp:Refresh(), .T. ) ;
		Message "Máscara Empresa ( ?? )"  Of oDlg
	@ 124, 50 Button oButMarc Prompt "&Marcar"    Size 32, 12 Pixel Action ( MarcaMas( oLbx, aVetor, cMascEmp, .T. ), VerTodos( aVetor, @lChk, oChkMar ) ) ;
		Message "Marcar usando máscara ( ?? )"    Of oDlg
	@ 124, 90 Button oButDMar Prompt "&Desmarcar" Size 32, 12 Pixel Action ( MarcaMas( oLbx, aVetor, cMascEmp, .F. ), VerTodos( aVetor, @lChk, oChkMar ) ) ;
		Message "Desmarcar usando máscara ( ?? )" Of oDlg

	Define SButton From 111, 125 Type 1 Action ( RetSelecao( @aRet, aVetor , cEmpEsc ), oDlg:End() ) OnStop "Confirma a Seleção"  Enable Of oDlg
	Define SButton From 111, 158 Type 2 Action ( IIf( lTeveMarc, aRet := aMarcadas, .T. ), oDlg:End() ) OnStop "Abandona a Seleção" Enable Of oDlg
	Activate MSDialog  oDlg Center

	RestArea( aSalvAmb )
	dbSelectArea( "SM0" )
	dbCloseArea()

Return aRet

/*/{Protheus.doc} MyOpenSM0
Funcao de processamento abertura do SM0 modo exclusivo.

@author Totvs TBC
@since 19/08/2015
@version 1.0

@return ${return}, ${return_description}
@param lShared, logical, Caso verdadeiro, indica que a tabela deve ser aberta em modo compartilhado, isto é, outros processos também poderão abrir esta tabela.

@type function
/*/
Static Function MyOpenSM0(lShared)

	Local lOpen := .F.
	Local nLoop := 0

	For nLoop := 1 To 20 //faz 20 tentativas

		If lShared
			OpenSm0() //Essa função realiza a abertura do SIGAMAT, utilizando como alias o SM0.
		Else
			OpenSM0Excl() //Essa função realiza a abertura do SIGAMAT em modo EXCLUSIVO, utilizando como alias o SM0.
		EndIf

		If !Empty( Select( "SM0" ) )
			lOpen := .T.
			Exit
		EndIf

		Sleep( 500 )

	Next nLoop

	If !lOpen
		Help(NIL, NIL, "ATENÇÃO", NIL, "Não foi possível a abertura da tabela " + ;
			IIf( lShared, "de empresas (SM0).", "de empresas (SM0) de forma exclusiva." ), 1, 0, NIL, NIL, NIL, NIL, NIL, {""})
	EndIf

Return lOpen

/*/{Protheus.doc} MarcaTodos
Funcao Auxiliar para marcar/desmarcar todos os itens do ListBox ativo.

@author Ernani Forastieri
@since 31/10/2017
@version 1.0
@return ${return}, ${return_description}
@param lMarca, logical, descricao
@param aVetor, array, descricao
@param oLbx, object, descricao
@type function
/*/
Static Function MarcaTodos( lMarca, aVetor, oLbx )
	Local  nI := 0

	For nI := 1 To Len( aVetor )
		aVetor[nI][1] := lMarca
	Next nI

	oLbx:Refresh()

Return NIL

/*/{Protheus.doc} InvSelecao
Funcao Auxiliar para inverter selecao do ListBox Ativo.

@author Ernani Forastieri
@since 31/10/2017
@version 1.0

@return ${return}, ${return_description}
@param aVetor, array, descricao
@param oLbx, object, descricao

@type function
/*/
Static Function InvSelecao( aVetor, oLbx )
	Local  nI := 0

	For nI := 1 To Len( aVetor )
		aVetor[nI][1] := !aVetor[nI][1]
	Next nI

	oLbx:Refresh()

Return NIL

/*/{Protheus.doc} RetSelecao
Funcao Auxiliar que monta o retorno com as selecoes.

@author Ernani Forastieri
@since 31/10/2017
@version 1.0

@return ${return}, ${return_description}
@param aRet, array, descricao
@param aVetor, array, descricao

@type function
/*/
Static Function RetSelecao( aRet, aVetor, cEmpEsc )
	Local  nI    := 0

	aRet := {}
	For nI := 1 To Len( aVetor )
		If aVetor[nI][1]
			If Empty(cEmpEsc)
				aAdd( aRet, { aVetor[nI][2] , aVetor[nI][3], aVetor[nI][2] +  aVetor[nI][3] } ) //SM0->M0_CODIGO, SM0->M0_CODFIL, SM0->M0_CODIGO + SM0->M0_CODFIL
			Else
				aAdd( aRet, { aVetor[nI][2] } ) // SM0->M0_CODFIL
			EndIf
		EndIf
	Next nI

Return NIL

/*/{Protheus.doc} MarcaMas
Funcao para marcar/desmarcar usando mascaras.

@author Ernani Forastieri
@since 31/10/2017
@version 1.0

@return ${return}, ${return_description}

@param oLbx, object, descricao
@param aVetor, array, descricao
@param cMascEmp, characters, descricao
@param lMarDes, logical, descricao

@type function
/*/
Static Function MarcaMas( oLbx, aVetor, cMascEmp, lMarDes )
	Local cPos1 := SubStr( cMascEmp, 1, 1 )
	Local cPos2 := SubStr( cMascEmp, 2, 1 )
	Local nPos  := oLbx:nAt
	Local nZ    := 0

	For nZ := 1 To Len( aVetor )
		If cPos1 == "?" .or. SubStr( aVetor[nZ][2], 1, 1 ) == cPos1
			If cPos2 == "?" .or. SubStr( aVetor[nZ][2], 2, 1 ) == cPos2
				aVetor[nZ][1] :=  lMarDes
			EndIf
		EndIf
	Next

	oLbx:nAt := nPos
	oLbx:Refresh()

Return NIL

/*/{Protheus.doc} VerTodos
Funcao auxiliar para verificar se estao todos marcardos ou nao.

@author Ernani Forastieri
@since 31/10/2017
@version 1.0

@return ${return}, ${return_description}

@param aVetor, array, descricao
@param lChk, logical, descricao
@param oChkMar, object, descricao

@type function
/*/
Static Function VerTodos( aVetor, lChk, oChkMar )
	Local lTTrue := .T.
	Local nI     := 0

	For nI := 1 To Len( aVetor )
		lTTrue := IIf( !aVetor[nI][1], .F., lTTrue )
	Next nI

	lChk := IIf( lTTrue, .T., .F. )
	oChkMar:Refresh()

Return NIL


