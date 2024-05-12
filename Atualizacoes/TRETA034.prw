#INCLUDE 'PROTHEUS.CH'
#INCLUDE 'TOTVS.CH'
#INCLUDE 'FWMVCDEF.CH'
#INCLUDE "TBICONN.CH"
#INCLUDE "TOPCONN.CH"

/*/{Protheus.doc} TRETA034
Cadastro de Lote de Cheque Troco.

@author Pablo Cavalcante
@since 16/03/2014
@version 1.0

@return ${return}, ${return_description}

@type function
/*/

User Function TRETA034()
	Local oBrowse
	Local lSrvPDV := SuperGetMV("MV_XSRVPDV",,.T.) //Servidor PDV

	If !lSrvPDV //se for na retaguarda disponibiliza o cadastro, caso contrario mostra mensagem...
		oBrowse := FWMBrowse():New()
		oBrowse:SetAlias('UF1')
		oBrowse:SetDescription('Cadastro de Lote de Cheque Troco')

		oBrowse:Activate()

	Else
		MsgStop("O Cadastro de Lote Cheque Troco esta disponivel somente na retaguarda!","Atenção")

	EndIf

Return NIL

//-------------------------------------------------------------------
Static Function MenuDef()
	Local aRotina := {}

	ADD OPTION aRotina TITLE 'Visualizar'		    ACTION 'VIEWDEF.TRETA034' OPERATION 2 ACCESS 0
	ADD OPTION aRotina TITLE 'Incluir'				ACTION 'VIEWDEF.TRETA034' OPERATION 3 ACCESS 0
	ADD OPTION aRotina TITLE 'Alterar'      	 	ACTION 'VIEWDEF.TRETA034' OPERATION 4 ACCESS 0
	ADD OPTION aRotina TITLE 'Excluir'       		ACTION 'VIEWDEF.TRETA034' OPERATION 5 ACCESS 0
	ADD OPTION aRotina TITLE 'Impressão' 			ACTION 'U_UFINR480()'     OPERATION 3 ACCESS 0
	ADD OPTION aRotina TITLE 'Remessa p/ Caixa' 	ACTION 'U_TRETB034(1)'    OPERATION 7 ACCESS 0
	ADD OPTION aRotina TITLE 'Transf. Entre Caixas' ACTION 'U_TRETB034(2)'    OPERATION 10 ACCESS 0

	If ExistBlock("TR034MNU")
		aRotina := ExecBlock("TR034MNU",.F.,.F.,aRotina)
	EndIf

Return aRotina

//-------------------------------------------------------------------
Static Function ModelDef()

// Cria a estrutura a ser usada no Modelo de Dados
	Local oStruUF1 := FWFormStruct( 1, 'UF1', /*bAvalCampo*/,/*lViewUsado*/ )
	Local oStruUF2 := FWFormStruct( 1, 'UF2', { |cCampo| COMP11STRU(cCampo) },  ) // Função executada para validar os campos exibidos
	Local oModel

// Cria o objeto do Modelo de Dados
	oModel := MPFormModel():New('TRETM034', /*bPreValidacao*/, {|oModel| VALTOTALCH(oModel) }, /*bCommit*/, /*bCancel*/ )
//oModel := MPFormModel():New('COMP011MODEL', /*bPreValidacao*/, { |oMdl| COMP011POS( oMdl ) }, /*bCommit*/, /*bCancel*/ )

// Adiciona ao modelo uma estrutura de formul·rio de ediÁ?o por campo
	oModel:AddFields( 'UF1MASTER', /*cOwner*/, oStruUF1, /*bPreValidacao*/, /*bPosValidacao*/, /*bCarga*/ )

// Adiciona a chave primaria da tabela principal
	oModel:SetPrimaryKey({ "UF1_FILIAL" , "UF1_COD" , "UF1_AGENCI" , 'UF1_NUMCON' , 'UF1_SEQUEN' })  //UF1_FILIAL+UF1_COD+UF1_AGENCI+UF1_NUMCON+UF1_SEQUEN

// Adiciona ao modelo uma componente de grid
	oModel:AddGrid( 'UF2DETAIL', 'UF1MASTER', oStruUF2 )

// Faz relacionamento entre os componentes do model
	oModel:SetRelation( 'UF2DETAIL', { {'UF2_FILIAL', 'xFilial( "UF2" )'}, {'UF2_BANCO', 'UF1_COD'}, {'UF2_AGENCI', 'UF1_AGENCI'}, {'UF2_CONTA', 'UF1_NUMCON'}, {'UF2_SEQUEN', 'UF1_SEQUEN'} }, UF2->( IndexKey( 1 ) ) )

// Liga o controle de nao repeticao de linha
	oModel:GetModel( 'UF2DETAIL' ):SetUniqueLine( { 'UF2_NUM' } )

// Adiciona a descricao do Modelo de Dados
	oModel:SetDescription( 'Modelo de Dados de Lote de Cheque Troco' )

// Adiciona a descrição dos Componentes do Modelo de Dados
	oModel:GetModel( 'UF1MASTER' ):SetDescription( 'Dados do Lote de Cheque Troco' )
	oModel:GetModel( 'UF2DETAIL' ):SetDescription( 'Dados dos Cheques Trocos' )

// Liga a validaÁ?o da ativacao do Modelo de Dados
//oModel:SetVldActivate( { |oModel| COMP011ACT( oModel ) } )

// Adiciona ao modelo uma estrutura de formulário de campos calculados
// AddCalc(cId, cOwner , cIdForm , cIdField , cIdCalc, cOperation, bCond
	oModel:AddCalc( 'TRET34CALC', 'UF1MASTER', 'UF2DETAIL', 'UF2_NUM'  , 'UF1_NCHEQU', 'COUNT', { | oModel | TRET34CAL( oModel, .T. ) },,'Nro de Cheques' )
	oModel:AddCalc( 'TRET34CALC', 'UF1MASTER', 'UF2DETAIL', 'UF2_VALOR', 'UF1_TOTAL' , 'SUM'  , { | oModel | TRET34CAL( oModel, .F. ) },,'Total dos Cheques' )

Return oModel

//-------------------------------------------------------------------
Static Function ViewDef()
// Cria um objeto de Modelo de Dados baseado no ModelDef do fonte informado
	Local oModel   := FWLoadModel( 'TRETA034' )
// Cria a estrutura a ser usada na View
	Local oStruUF1 := FWFormStruct( 2, 'UF1' ) //Local oStruUF1 := FWFormStruct( 2, 'UF1', { |cCampo| COMP11STRU(cCampo) } )
	Local oStruUF2 := FWFormStruct( 2, 'UF2' , { |cCampo| COMP11STRU(cCampo) } )
	Local oView
	Local oCalc1
	//Local cCampos := {}

// Crio os Agrupamentos de Campos
// AddGroup( cID, cTitulo, cIDFolder, nType )   nType => ( 1=Janela; 2=Separador )
//oStruUF1:AddGroup( 'GRUPO01', 'Alguns Dados', '', 1 )
//oStruUF1:AddGroup( 'GRUPO02', 'Outros Dados', '', 2 )

// Altero propriedades dos campos da estrutura, no caso colocando cada campo no seu grupo
//
// SetProperty( <Campo>, <Propriedade>, <Valor> )
//
// Propriedades existentes para View (lembre-se de incluir o FWMVCDEF.CH):
//			MVC_VIEW_IDFIELD
//			MVC_VIEW_ORDEM
//			MVC_VIEW_TITULO
//			MVC_VIEW_DESCR
//			MVC_VIEW_HELP
//			MVC_VIEW_PICT
//			MVC_VIEW_PVAR
//			MVC_VIEW_LOOKUP
//			MVC_VIEW_CANCHANGE
//			MVC_VIEW_FOLDER_NUMBER
//			MVC_VIEW_GROUP_NUMBER
//			MVC_VIEW_COMBOBOX
//			MVC_VIEW_MAXTAMCMB
//			MVC_VIEW_INIBROW
//			MVC_VIEW_VIRTUAL
//			MVC_VIEW_PICTVAR
//
//oStruUF1:SetProperty( '*'         , MVC_VIEW_GROUP_NUMBER, 'GRUPO01' )
//oStruUF1:SetProperty( 'ZA0_QTDMUS', MVC_VIEW_GROUP_NUMBER, 'GRUPO02' )
//oStruUF1:SetProperty( 'ZA0_TIPO'  , MVC_VIEW_GROUP_NUMBER, 'GRUPO02' )

// Cria o objeto de View
	oView := FWFormView():New()

// Define qual o Modelo de dados ser· utilizado
	oView:SetModel( oModel )

// Remove campos da estrutura
//oStruUF2:RemoveField('UF2_BANCO')
//oStruUF2:RemoveField('UF2_AGENCI')
//oStruUF2:RemoveField('UF2_CONTA')

//Adiciona no nosso View um controle do tipo FormFields(antiga enchoice)
	oView:AddField( 'VIEW_UF1', oStruUF1, 'UF1MASTER' )

//Adiciona no nosso View um controle do tipo Grid (antiga Getdados)
	oView:AddGrid( 'VIEW_UF2', oStruUF2, 'UF2DETAIL' )

// Cria o objeto de Estrutura
	oCalc1 := FWCalcStruct( oModel:GetModel( 'TRET34CALC' ) )
//Adiciona no nosso View um controle do tipo FormGrid(antiga newgetdados)
	oView:AddField( 'VIEW_CALC', oCalc1, 'TRET34CALC' )

// Cria um "box" horizontal para receber cada elemento da view
	oView:CreateHorizontalBox( 'SUPERIOR', 35 )
	oView:CreateHorizontalBox( 'INFERIOR', 50 )
	oView:CreateHorizontalBox( 'RODAPE'  , 15 )

// Quebra em 2 "box" vertical para receber algum elemento da view
	oView:CreateVerticalBox( 'EMBAIXOESQ', 90, 'INFERIOR' )
	oView:CreateVerticalBox( 'EMBAIXODIR', 10, 'INFERIOR' )

// Relaciona o identificador (ID) da View com o "box" para exibição
	oView:SetOwnerView( 'VIEW_UF1' , 'SUPERIOR' )
	oView:SetOwnerView( 'VIEW_UF2' , 'EMBAIXOESQ' )
	oView:SetOwnerView( 'VIEW_CALC', 'RODAPE' )

//oView:SetViewAction( 'BUTTONOK'    , { |oView| NOME_DA_ACAO() } )
//oView:SetViewAction( 'BUTTONCANCEL', { |oView| NOME_DA_ACAO() } )
//oView:SetViewAction( 'REFRESH', { |oView| LOJ001SOMA() } )

// titulo dos componentes
	oView:EnableTitleView('VIEW_UF1' ,/*'cabecalho'*/)
	oView:EnableTitleView('VIEW_UF2' ,/*'itens'*/)
	oView:EnableTitleView('VIEW_CALC','Totalizadores')

// edicao do grid
//oView:SetViewProperty( 'VIEW_UF2', "ENABLEDGRIDDETAIL", { 25 } )

// Criar novo botao na barra de botoes
//oView:AddUserButton( 'Adicionar Cheques', 'CLIPS', { |oView| TELA_CHEQUES() } )

// Acrescenta um objeto externo ao View do MVC
// AddOtherObject(cFormModelID,bBloco)
// cIDObject - Id
// bBloco    - Bloco chamado devera ser usado para se criar os objetos de tela externos ao MVC.
	oView:AddOtherObject("OTHER_PANEL", {|oPanel| ADDCHBUT(oPanel)})

// Associa ao box que ira exibir os outros objetos
	oView:SetOwnerView("OTHER_PANEL",'EMBAIXODIR')

Return oView

//-------------------------------------------------------------------
Static Function ADDCHBUT( oPanel )
	Local oModel     := FWModelActive()
	Local nOperation := oModel:GetOperation()

	If nOperation == MODEL_OPERATION_UPDATE .or. nOperation == MODEL_OPERATION_INSERT
		// Ancoramos os objetos no oPanel passado
		@ 10, 10 Button 'Adic. Cheques' Size 38, 13 Message 'Adicionar Cheques na FormGrid' Pixel Action ADCHEQUES() of oPanel
	EndIf

Return NIL


/*/{Protheus.doc} VALTOTALCH
Alimenta campos UF1_NCHEQU e UF1_TOTAL do cabeçalho da rotina ao salvar 
@author Felipe Sousa - Duofy
@since 29/01/2024
/*/
Static Function VALTOTALCH(oModel)

	Local oModelMaster := oModel:GetModel( 'UF1MASTER' )
	Local oModelUF1    := oModel:GetModel( 'TRET34CALC' )
	Local nroCheques   := oModelUF1:GetValue( 'UF1_NCHEQU' )
	Local totalCheques := oModelUF1:GetValue( 'UF1_TOTAL' )
	Local nOperation   := oModelMaster:GetOperation()

	If nOperation == MODEL_OPERATION_UPDATE .or. nOperation == MODEL_OPERATION_INSERT
		// Atribui os valores calculados aos campos correspondentes
		oModelMaster:LoadValue('UF1_NCHEQU', nroCheques)
		oModelMaster:LoadValue('UF1_TOTAL', totalCheques)

	EndIf

Return .T.

//-------------------------------------------------------------------
Static Function ADCHEQUES()

	Local oModel     := FWModelActive()
	Local oView 	 := FWViewActive()
	//Local nOperation := oModel:GetOperation()
	Local oModelUF1  := oModel:GetModel( 'UF1MASTER' )
	Local oModelUF2  := oModel:GetModel( 'UF2DETAIL' )
	Local cBanco	 := Space(TamSx3("UF1_COD")[1])
	Local cAgencia 	 := Space(TamSx3("UF1_AGENCI")[1])
	Local cConta 	 := Space(TamSx3("UF1_NUMCON")[1])
	Local cCheque 	 := Space(TamSx3("UF2_NUM")[1])
	Local cBenef 	 := Space(TamSx3("EF_BENEF")[1])
	//Local cForn 	 := Space(TamSX3("E2_FORNECE")[1])
	Local cHist 	 := Space(TamSx3("EF_HIST")[1])
	Local nValor     := 0
	Local nQtd 	     := 0
	Local nEspLin    := 5
	Local nEspLarg   := 0
	Local nOpca      := 0
	Local nI

	cBanco 	 := oModelUF1:GetValue('UF1_COD')
	cAgencia := oModelUF1:GetValue('UF1_AGENCI')
	cConta   := oModelUF1:GetValue('UF1_NUMCON')

	DEFINE MSDIALOG oDlg FROM 15,6 TO 244,485 TITLE OemToAnsi("Geração de Cheque Troco") PIXEL
	oDlg:lMaximized := .F.

	oPanel := TPanel():New(0,0,'',oDlg,, .T., .T.,, ,20,20)
	oPanel:Align := CONTROL_ALIGN_ALLCLIENT

	@ 000+nEspLin, 011+nEspLarg TO 028+nEspLin, 193+nEspLarg OF oPanel PIXEL
	@ 031+nEspLin, 011+nEspLarg TO 105+nEspLin, 193+nEspLarg OF oPanel PIXEL

//dados do banco
	@ 002+nEspLin, 016+nEspLarg SAY OemToAnsi("Banco") SIZE 021, 007 OF oPanel PIXEL
	@ 011+nEspLin, 016+nEspLarg MSGET oBanco VAR cBanco SIZE 021, 008 OF oPanel Hasbutton PIXEL Valid .T. F3 "XSA6" Picture "@!" WHEN .F.

	@ 002+nEspLin, 052+nEspLarg SAY OemToAnsi("Agência") SIZE 028, 007 OF oPanel PIXEL
	@ 011+nEspLin, 052+nEspLarg MSGET cAgencia SIZE 028, 008 OF oPanel PIXEL Valid .T. Picture "@!"	WHEN .F.

	@ 002+nEspLin, 087+nEspLarg SAY OemToAnsi("Conta") SIZE 028, 007 OF oPanel PIXEL
	@ 011+nEspLin, 087+nEspLarg MSGET cConta SIZE 039, 008 OF oPanel PIXEL Valid .T. Picture "@!" WHEN .F.

	@ 002+nEspLin, 134+nEspLarg SAY OemToAnsi("N. Inicial Cheq.") SIZE 046, 007 OF oPanel PIXEL
	@ 011+nEspLin, 133+nEspLarg MSGET oCheque VAR cCheque SIZE 049, 008 OF oPanel PIXEL Valid AjustNum(@cCheque,@oCheque) .AND. !empty(cCheque) Picture "999999"

//dados digitados
	@ 033+nEspLin, 018+nEspLarg SAY OemToAnsi("Valor do Cheque Troco") SIZE 065, 007 OF oPanel PIXEL
	@ 043+nEspLin, 018+nEspLarg MSGET nValor Picture "@E 9999,999,999.99" Valid (nValor>=0) SIZE 063, 008 OF oPanel Hasbutton PIXEL

	@ 033+nEspLin, 120+nEspLarg SAY OemToAnsi("Quantidade") SIZE 046, 007 OF oPanel PIXEL
	@ 043+nEspLin, 119+nEspLarg MSGET nQtd Picture "@E 9999,999,999" Valid (nQtd>0) SIZE 063, 008 OF oPanel Hasbutton PIXEL

	@ 056+nEspLin, 018+nEspLarg SAY OemToAnsi("Historico") SIZE 053, 007 OF oPanel PIXEL
	@ 066+nEspLin, 018+nEspLarg MSGET cHist Picture "@!S35" SIZE 168, 008 OF oPanel PIXEL

	@ 079+nEspLin, 018+nEspLarg SAY OemToAnsi("Beneficiario") SIZE 053, 007 OF oPanel PIXEL
	@ 089+nEspLin, 018+nEspLarg MSGET cBenef Picture "@!S30" SIZE 168, 008 OF oPanel PIXEL

	DEFINE SBUTTON FROM 07, 204 TYPE 1 ACTION ( nOpca := 1, Iif(VALINCCH(oDlg), oDlg:End(), nOpca:=0) ) ENABLE OF oPanel
	DEFINE SBUTTON FROM 20, 204 TYPE 2 ACTION {|| nOpca := 0, oDlg:End()} ENABLE OF oPanel

	ACTIVATE MSDIALOG oDlg CENTERED

	If nOpca == 1

		nI        := 0
		nLinha 	  := oModelUF2:Length()

		oModelUF2:GoLine( nLinha )
		nVlParc   := nValor // (nValor/nQtd)

		For nI:=1 to nQtd
			If valcheque(cBanco,cAgencia,cConta,cCheque)
				If empty(oModelUF2:GetValue( 'UF2_NUM' )) .and. empty(oModelUF2:GetValue( 'UF2_VALOR' ))
					oModelUF2:SetValue( 'UF2_NUM'   , cCheque )
					oModelUF2:SetValue( 'UF2_VALOR' , nVlParc )
					oModelUF2:SetValue( 'UF2_HIST'  , cHist )
					oModelUF2:SetValue( 'UF2_BENEF' , cBenef )
				Else
					nLinha++
					If oModelUF2:AddLine() == nLinha
						oModelUF2:GoLine( nLinha )
						oModelUF2:SetValue( 'UF2_NUM'   , cCheque )
						oModelUF2:SetValue( 'UF2_VALOR' , nVlParc )
						oModelUF2:SetValue( 'UF2_HIST'  , cHist )
						oModelUF2:SetValue( 'UF2_BENEF' , cBenef )
					Else
						Help( ,, 'HELP',, 'Nao incluiu linha no grid UF2' + CRLF + oModel:getErrorMessage()[6], 1, 0)
						nLinha 	 := oModelUF2:Length()
					EndIf
				EndIf
			EndIf
			cCheque := soma1( alltrim(cCheque) )
		Next nI

		oModelUF2:GoLine( 1 )
		oView:Refresh()

	Endif

Return NIL

/*/{Protheus.doc} VALINCCH
Valida inclusão de cheque troco

@author Pablo Nunes
@since 16/07/2023
/*/
Static Function VALINCCH(oDlg)
	Local nX
	Local lRet := .T.

	For nX := 1 To Len(oDlg:aControls)
		If ValType(oDlg:aControls[nX]) == "O" .and.;
				!Empty(oDlg:aControls[nX]:bValid)

			lRet := Eval(oDlg:aControls[nX]:bValid)
			If ValType(lRet) != "L"
				lRet := .T.
			Endif

			If !lRet
				Help( ,, 'HELP',, 'Preencha os dados obrigatórios: N. Inicial Cheq., Quantidade', 1, 0)
				Exit // Sai no primeiro campo invalido
			Endif

		Endif
	Next

Return lRet

/*/{Protheus.doc} TRET34CAL
Faz o calculo... [DESUSO]

@author Pablo Nunes
@since 16/07/2023
/*/
Static Function TRET34CAL( oModel, lPar )
	Local lRet := .T.

//If lPar
//	lRet := ( Mod( Val( oModel:GetValue( 'UF2DETAIL', 'UF2_' ) ) , 2 ) == 0 )
//Else
//	lRet := ( Mod( Val( oModel:GetValue( 'UF2DETAIL', 'UF2_' ) ) , 2 ) <> 0 )
//EndIf

Return lRet

/*/{Protheus.doc} TRETB034
Remessa para Caixa
@type function
 
@author Pablo Nunes
@since 16/07/2023
/*/
User Function TRETB034(nOpc)
	Local lChTrOp 	:= SuperGetMV("MV_XCHTROP",,.F.) //Controle de Cheque Troco por Operador (default .F.)
	Local oFont14   := TFont():New ("Arial",, 14,, .F.)
	Local cTitulo 	:= "Remessa para Caixa"
	Local oButton1
	Local oButton2
	Local oButton3
	Local oGroup1
	Local oGroup2
	Local oGroup3

	Default nOpc := 1 //por padrao é remessa para caixa

	Private oPDV
	Private cPDVDes 	:= Space(TamSx3("LG_PDV")[1])
	Private cPDVOri 	:= Space(Len(cPDVDes))
	Private cBanco		:= Space(TamSx3("UF1_COD")[1])
	Private cAgencia 	:= Space(TamSx3("UF1_AGENCI")[1])
	Private cConta 		:= Space(TamSx3("UF1_NUMCON")[1])
	Private cChequeD 	:= Space(TamSx3("UF2_NUM")[1])
	Private cChequeA 	:= Padl("",TamSx3("UF2_NUM")[1],"9")
	Private cEstDes 	:= Space(TamSx3("LG_CODIGO")[1])
	Private cEstOri 	:= Space(Len(cEstDes))
	Private cNomeDe 	:= Space(TamSx3("A6_NOME")[1])
	Private cNomeOr		:= Space(TamSX3("A6_NOME")[1])
	Private cOpeDes		:= Space(TamSx3("A6_COD")[1])
	Private cOpeOri		:= Space(TamSx3("A6_COD")[1])
	Private nQtde   := 0
	Private oQtde
	Private nTotal  := 0
	Private oTotal
	Private lLib	:= .F.
	Private oGet5

	Static oDlg

	DEFINE MSDIALOG oDlg TITLE cTitulo FROM 000, 000  TO 500, 500 COLORS 0, 16777215 PIXEL

	//cabeçalho
	@ 005, 007 GROUP oGroup1 TO 092, 243 OF oDlg COLOR 0, 16777215 PIXEL

	If nOpc == 1
		If lChTrOp

			@ 010, 016 SAY "Operador" SIZE 025, 007 OF oDlg COLORS CLR_BLACK PIXEL FONT oFont14
			@ 020, 016 MSGET oCodDe VAR cOpeDes SIZE 030, 007 OF oDlg COLORS CLR_BLACK HASBUTTON PIXEL F3 "23" FONT oFont14 Valid Empty(cOpeDes) .or. (ExistCpo('SX5','23'+cOpeDes) .and. DescOp(1))

			@ 010, 052 SAY "Descrição" SIZE 040, 007 OF oDlg COLORS CLR_BLACK PIXEL FONT oFont14
			@ 020, 052 MSGET oNomeDe VAR cNomeDe SIZE 100, 007 OF oDlg COLORS CLR_BLACK PIXEL FONT oFont14 When .F.

		Else

			@ 010, 016 SAY "Estação" SIZE 025, 007 OF oDlg COLORS CLR_BLACK PIXEL FONT oFont14
			@ 020, 016 MSGET oCodDe VAR cEstDes SIZE 030, 007 OF oDlg COLORS CLR_BLACK HASBUTTON PIXEL F3 "SLG" FONT oFont14 Valid Empty(cEstDes) .or. DescPdv(1)

			@ 010, 052 SAY "PDV" SIZE 040, 007 OF oDlg COLORS CLR_BLACK PIXEL FONT oFont14
			@ 020, 052 MSGET oPDV VAR cPDVDes SIZE 040, 007 OF oDlg COLORS CLR_BLACK HASBUTTON PIXEL FONT oFont14 When .F. Valid (Empty(cPDVDes) .or. vLG_PDV(cPDVDes))

			@ 010, 095 SAY "Descrição" SIZE 040, 007 OF oDlg COLORS CLR_BLACK PIXEL FONT oFont14
			@ 020, 095 MSGET oNomeDe VAR cNomeDe SIZE 060, 007 OF oDlg COLORS CLR_BLACK PIXEL FONT oFont14 When .F.

		EndIf

	else

		If lChTrOp

			@ 010, 016 SAY "Op. Ori." SIZE 030, 007 OF oDlg COLORS CLR_BLACK PIXEL FONT oFont14
			@ 020, 016 MSGET oCodOr VAR cOpeOri SIZE 030, 007 OF oDlg COLORS CLR_BLACK HASBUTTON PIXEL F3 "23" FONT oFont14 Valid Empty(cOpeOri) .or. (ExistCpo('SX5','23'+cOpeOri) .and. DescOp(2))

			@ 010, 048 SAY "Descrição" SIZE 040, 007 OF oDlg COLORS CLR_BLACK PIXEL FONT oFont14
			@ 020, 048 MSGET oPDVOri VAR cNomeOr SIZE 058, 007 OF oDlg COLORS CLR_BLACK HASBUTTON PIXEL FONT oFont14 When .F.

			@ 008, 111 GROUP oGroup3 TO 034, 113 OF oDlg COLOR 0, 16777215 PIXEL

			@ 010, 117 SAY "Op. Dest." SIZE 030, 007 OF oDlg COLORS CLR_BLACK PIXEL FONT oFont14
			@ 020, 117 MSGET oCodDe VAR cOpeDes SIZE 030, 007 OF oDlg COLORS CLR_BLACK HASBUTTON PIXEL F3 "23" FONT oFont14 Valid Empty(cOpeDes) .or. (ExistCpo('SX5','23'+cOpeDes) .and. DescOp(1))

			@ 010, 150 SAY "Descrição" SIZE 040, 007 OF oDlg COLORS CLR_BLACK PIXEL FONT oFont14
			@ 020, 150 MSGET oNomeDe VAR cNomeDe SIZE 058, 007 OF oDlg COLORS CLR_BLACK HASBUTTON PIXEL FONT oFont14 When .F.

		Else

			@ 010, 016 SAY "Estação Ori." SIZE 025, 007 OF oDlg COLORS CLR_BLACK PIXEL FONT oFont14
			@ 020, 016 MSGET oCodOr VAR cEstOri SIZE 030, 007 OF oDlg COLORS CLR_BLACK HASBUTTON PIXEL F3 "SLG" FONT oFont14 Valid Empty(cEstOri) .or. DescPdv(2)

			@ 010, 048 SAY "PDV Origem" SIZE 040, 007 OF oDlg COLORS CLR_BLACK PIXEL FONT oFont14
			@ 020, 048 MSGET oPDVOri VAR cPDVOri SIZE 040, 007 OF oDlg COLORS CLR_BLACK HASBUTTON PIXEL FONT oFont14 When .F. Valid (Empty(cPDVDes) .or. vLG_PDV(cPDVDes))

			@ 008, 111 GROUP oGroup3 TO 034, 113 OF oDlg COLOR 0, 16777215 PIXEL

			@ 010, 117 SAY "Estação Dest." SIZE 025, 007 OF oDlg COLORS CLR_BLACK PIXEL FONT oFont14
			@ 020, 117 MSGET oCodDe VAR cEstDes SIZE 030, 007 OF oDlg COLORS CLR_BLACK HASBUTTON PIXEL F3 "SLG" FONT oFont14 Valid Empty(cEstDes) .or. DescPdv(1)

			@ 010, 150 SAY "PDV Destino" SIZE 040, 007 OF oDlg COLORS CLR_BLACK PIXEL FONT oFont14
			@ 020, 150 MSGET oPDV VAR cPDVDes SIZE 040, 007 OF oDlg COLORS CLR_BLACK HASBUTTON PIXEL FONT oFont14 When .F. Valid (Empty(cPDVDes) .or. vLG_PDV(cPDVDes))

			@ 020, 095 MSGET oNomeDe VAR cNomeDe SIZE 060, 007 OF oDlg COLORS CLR_BLACK PIXEL FONT oFont14 When .F.
			oNomeDe:Hide()

		EndIf

	EndIf

	//dados do banco e cheque (filtros)
	@ 036, 010 GROUP oGroup3 TO 038, 240 OF oDlg COLOR 0, 16777215 PIXEL

	@ 042, 016 SAY "Banco" SIZE 021, 007 OF oDlg PIXEL FONT oFont14
	@ 052, 016 MSGET oBanco VAR cBanco SIZE 021, 008 OF oDlg HASBUTTON PIXEL F3 "XSA6" Picture "@!" WHEN .T. FONT oFont14 Valid CARREGAR()

	@ 042, 052 SAY "Agência" SIZE 028, 007 OF oDlg PIXEL FONT oFont14
	@ 052, 052 MSGET cAgencia SIZE 028, 008 OF oDlg PIXEL Picture "@!" FONT oFont14 Valid CARREGAR()

	@ 042, 087 SAY "Conta" SIZE 028, 007 OF oDlg PIXEL FONT oFont14
	@ 052, 087 MSGET cConta SIZE 039, 008 OF oDlg PIXEL Picture "@!" FONT oFont14 Valid CARREGAR()

	@ 067, 016 SAY "Cheque De ?" SIZE 046, 010 OF oDlg PIXEL FONT oFont14
	@ 077, 016 MSGET oChequeD VAR cChequeD SIZE 049, 008 OF oDlg PIXEL Picture "999999" FONT oFont14  Valid AjustNum(@cChequeD,@oChequeD) .AND. CARREGAR()

	@ 067, 087 SAY "Cheque Ate ?" SIZE 046, 010 OF oDlg PIXEL FONT oFont14
	@ 077, 087 MSGET oChequeA VAR cChequeA SIZE 049, 008 OF oDlg PIXEL Picture "999999" FONT oFont14 Valid AjustNum(@cChequeA,@oChequeA) .AND. CARREGAR()

	@ 077, 202 BUTTON oButton3 PROMPT "Carregar" SIZE 037, 012 OF oDlg PIXEL ACTION MsAguarde( {|| CARREGAR()}, "Aguarde", "Selecionando registros...", .F. )

	@ 095, 007 GROUP oGroup2 TO 225, 243 OF oDlg COLOR 0, 16777215 PIXEL
	oBtn1 := tButton():New(101, 016, "Marca Todos      ", oDlg, {|| fMarTudo(1)}, 050, 012,,,, .T.)
	oBtn2 := tButton():New(101, 076, "Desmarca Todos   ", oDlg, {|| fMarTudo(2)}, 050, 012,,,, .T.)
	oBtn3 := tButton():New(101, 136, "Inverte Seleção  ", oDlg, {|| fMarTudo(3)}, 050, 012,,,, .T.)

	oGet5 := fMSNewGe1()
	bSvblDb5 := oGet5:oBrowse:bLDblClick
	oGet5:oBrowse:bLDblClick := {|| if(oGet5:oBrowse:nColPos!=0, CLIQUE5(), GdRstDblClick(@oGet5, @bSvblDb5))}
	oGet5:oBrowse:bChange := {|| Refresh5()}

	@ 227, 010 TO 246, 080 LABEL " Qtd Cheques " OF oDlg PIXEL
	@ 236, 048 SAY oQtde VAR nQtde Size 070,010 OF oDlg Font oFont COLOR CLR_BLACK Picture "@E 999,999,999.99" PIXEL

	@ 227, 085 TO 246, 155 LABEL " Total " OF oDlg PIXEL
	@ 236, 123 SAY oTotal VAR nTotal Size 070,010 OF oDlg Font oFont COLOR CLR_BLACK Picture "@E 999,999,999.99" PIXEL

	@ 233, 160 BUTTON oButton1 PROMPT "Transferir" SIZE 037, 012 OF oDlg PIXEL ACTION (TRANSFERIR(cOpeDes,cPDVDes))
	@ 233, 205 BUTTON oButton2 PROMPT "Fechar"     SIZE 037, 012 OF oDlg PIXEL ACTION oDlg:End()

	ACTIVATE MSDIALOG oDlg CENTERED

Return

//-------------------------------------------------------------------
// Valida o codigo do PDV digitado.
//-------------------------------------------------------------------
Static Function vLG_PDV(cPDVDes)
	Local aArea  	:= GetArea()
	Local aAreaSLG 	:= SLG->(GetArea())
	Local cCondicao	:= ""
	Local bCondicao
	Local lRet   	:= .T.

	cCondicao := " LG_FILIAL = '" + xFilial("SLG") + "'"
	cCondicao += " .AND. LG_PDV = '" + cPDVDes + "'"

// limpo os filtros da SLG
	SLG->(DbClearFilter())

// executo o filtro na SLG
	bCondicao 	:= "{|| " + cCondicao + " }"
	SLG->(DbSetFilter(&bCondicao,cCondicao))

// vou para a primeira linha
	SLG->(DbGoTop())

	If !Empty(cPDVDes) .and. SLG->(Eof())
		lRet := .F.
		MsgAlert("O código de PDV informando é inválido.","Atenção")
	EndIf

// limpo os filtros da SLG
	SLG->(DbClearFilter())

	RestArea(aAreaSLG)
	RestArea(aArea)
Return lRet

Static Function AjustNum(cCheque, oCheque)

	if !empty(cCheque)
		cCheque := StrZero(Val(cCheque),6,0)
		oCheque:Refresh()
	endif

Return .T.

//-------------------------------------------------------------------
Static Function DescPdv(nOpc)

	If nOpc == 1
		cPDVDes := POSICIONE("SLG",1,XFILIAL("SLG")+cEstDes,"LG_PDV")
		cNomeDe := SLG->LG_NOME
		oPdv:Refresh()
	Else
		cPDVOri := POSICIONE("SLG",1,XFILIAL("SLG")+cEstOri,"LG_PDV")
	Endif

Return .T.

//-------------------------------------------------------------------
Static Function DescOp(nOpc)

	If nOpc == 1
		cNomeDe := Posicione("SA6",1,xFilial("SA6")+cOpeDes,"A6_NOME")
		oNomeDe:Refresh()
	Else
		cNomeOr := Posicione("SA6",1,xFilial("SA6")+cOpeOri,"A6_NOME")
	Endif

Return .T.

//------------------------------------------------
Static Function fMSNewGe1()
	Local nX
	Local aHeaderEx    := {}
	Local aColsEx      := {}
	//Local aFieldFill   := {}
	Local aFields      := {"MARK","UF2_NUM", "UF2_VALOR","UF2_BENEF","UF2_HIST","RECNO"}
	Local aAlterFields := {"MARK"}
	Local nLinMax 	   := 999  // Quantidade delinha na getdados

	// Define field properties
	Aadd(aHeaderEx,{'','MARK','@BMP',2,0,'','€€€€€€€€€€€€€€','C','','','',''})
	For nX := 1 to Len(aFields)
		If !empty(GetSx3Cache(aFields[nX], "X3_CAMPO"))
			aadd(aHeaderEx, U_UAHEADER(aFields[nX]) )
		Endif
	Next nX
	Aadd(aHeaderEx,{"RECNO","RECNO","@E 99999999999999999",17,0,"","","N","","","",""})

	if Len(aColsEx) == 0
		Aadd(aColsEx, {"LBNO", space(tamsx3("UF2_NUM")[1]), 0 /*"UF2_VALOR"*/, space(tamsx3("UF2_BENEF")[1]), space(tamsx3("UF2_HIST")[1]), 0, .F.})
	endif

//oMSNewGe1 := MsNewGetDados():New( 101, 010, 223, 239, GD_INSERT+GD_DELETE+GD_UPDATE, "AllwaysTrue", "AllwaysTrue", "+Field1+Field2", aAlterFields,, 999, "AllwaysTrue", "", "AllwaysTrue", oDlg, aHeaderEx, aColsEx)

Return MsNewGetDados():New( 120/*101*/, 010, 223, 239, GD_UPDATE, "AllwaysTrue", "AllwaysTrue", "AllwaysTrue",;
		aAlterFields, , nLinMax, "AllwaysTrue", "AllwaysTrue", "U_DelVariant()", oDlg, aHeaderEx, aColsEx)

//------------------------------------------------
Static Function CLIQUE5()

	If len(oGet5:aCols) == 0
		Return()
	Endif

	If oGet5:aCols[oGet5:NAT][aScan(oGet5:aHeader,{|x| AllTrim(x[2])=="MARK"})] == "LBOK"
		oGet5:aCols[oGet5:NAT][aScan(oGet5:aHeader,{|x| AllTrim(x[2])=="MARK"})] := "LBNO"
	Else
		oGet5:aCols[oGet5:NAT][aScan(oGet5:aHeader,{|x| AllTrim(x[2])=="MARK"})] := "LBOK"
	Endif

	oGet5:oBrowse:REFRESH()
	Refresh5()

Return

//------------------------------------------------
Static Function REFRESH5()
	Local nPosMark := aScan(oGet5:aHeader,{|x| AllTrim(x[2])=="MARK"})
	Local nPosVal  := aScan(oGet5:aHeader,{|x| AllTrim(x[2])=="UF2_VALOR"})
	Local nX

	nQtde  := 0
	nTotal := 0

	If len(oGet5:aCols) == 0
		Return()
	Endif

	For nX:=1 to len(oGet5:aCols)

		If oGet5:aCols[nX][nPosMark] == "LBOK"
			nQtde++
			nTotal += oGet5:aCols[nX][nPosVal]
		EndIf

	Next nX

	oQtde:Refresh()
	oTotal:Refresh()

Return()

//-------------------------------------------------------------------
Static Function CARREGAR()
	Local aArea  := GetArea()
	Local cQry := ""
	Local lChTrOp := SuperGetMV("MV_XCHTROP",,.F.) //Controle de Cheque Troco por Operador (default .F.)

	oGet5:acols := {}

	#IFDEF TOP

		cQry := "SELECT UF2.R_E_C_N_O_ RECUF2, UF2_NUM, UF2_VALOR, UF2_BENEF, UF2_HIST "
		cQry += " FROM " + RetSqlName("UF2") + " UF2"
		cQry += " WHERE UF2.D_E_L_E_T_ = ' ' "
		cQry += " AND UF2_FILIAL = '" + xFilial("UF2") + "' "
		If !Empty(cBanco)
			cQry += " AND UF2_BANCO = '" + cBanco + "' "
		EndIf
		If !Empty(cAgencia)
			cQry += " AND UF2_AGENCI = '" + cAgencia + "' "
		EndIf
		If !Empty(cConta)
			cQry += " AND UF2_CONTA = '" + cConta + "' "
		EndIf
		cQry += " AND UF2_NUM >= '" + cChequeD + "' "
		cQry += " AND UF2_NUM <= '" + cChequeA + "' "
		If lChTrOp
			If Empty(cOpeOri)
				cQry += " AND UF2_CODCX = '"+space(tamsx3("UF2_CODCX")[1])+"' "
			Else
				cQry += " AND UF2_CODCX = '"+cOpeOri+"' "
			EndIf
		Else
			If Empty(cPdvOri)
				cQry += " AND UF2_PDV = '"+space(tamsx3("UF2_PDV")[1])+"' "
			Else
				cQry += " AND UF2_PDV = '"+cPdvOri+"' "
			EndIf
		EndIf
		cQry += " AND UF2_DOC = '"+space(tamsx3("UF2_DOC")[1])+"' "
		cQry += " AND UF2_SERIE = '"+space(tamsx3("UF2_SERIE")[1])+"' "
		cQry += " AND UF2_STATUS <> '2' AND UF2_STATUS <> '3' " //remove as folhas de cheque usadas e inutilizadas
		cQry += " ORDER BY UF2_FILIAL, UF2_BANCO, UF2_AGENCI, UF2_CONTA, UF2_NUM"

		If Select("QAUX") > 0
			QAUX->(dbCloseArea())
		EndIf

		cQry := ChangeQuery(cQry)
		TcQuery cQry NEW Alias "QAUX"

		If QAUX->(!Eof())
			While QAUX->(!Eof())
				aadd(oGet5:acols, {"LBNO", QAUX->UF2_NUM, QAUX->UF2_VALOR, QAUX->UF2_BENEF, QAUX->UF2_HIST, QAUX->RECUF2, .F.})
				QAUX->( dbskip() )
			EndDo
		EndIf

		QAUX->(dbCloseArea())

	#ELSE

		cCondicao := " UF2_FILIAL = '" + xFilial("UF2") + "'"
		if !empty(cBanco) .and. !empty(cBanco) .And. !empty(cConta)
			cCondicao += " .AND. UF2_BANCO = '" + cBanco + "'"
			cCondicao += " .AND. UF2_AGENCI = '" + cAgencia + "'"
			cCondicao += " .AND. UF2_CONTA = '" + cConta + "'"
		endif

		cCondicao += " .AND. UF2_NUM >= '" + cChequeD + "'"
		cCondicao += " .AND. UF2_NUM <= '" + cChequeA + "'"
		If lChTrOp
			If Empty(cOpeOri)
				cCondicao += " .AND. UF2_CODCX = '"+space(tamsx3("UF2_CODCX")[1])+"'"
			Else
				cCondicao += " .AND. UF2_CODCX = '"+cOpeOri+"'"
			EndIf
		Else
			If Empty(cPdvOri)
				cCondicao += " .AND. UF2_PDV = '"+space(tamsx3("UF2_PDV")[1])+"'"
			Else
				cCondicao += " .AND. UF2_PDV = '"+cPdvOri+"'"
			EndIf
		EndIf
		cCondicao += " .AND. UF2_DOC = '"+space(tamsx3("UF2_DOC")[1])+"'"
		cCondicao += " .AND. UF2_SERIE = '"+space(tamsx3("UF2_SERIE")[1])+"'"
		cCondicao += " .AND. UF2_STATUS <> '2' .AND. UF2_STATUS <> '3'" //remove as folhas de cheque usadas e inutilizadas

// limpo os filtros da UF2
		UF2->(DbClearFilter())

// executo o filtro na UF2
		bCondicao 	:= "{|| " + cCondicao + " }"
		UF2->(DbSetFilter(&bCondicao,cCondicao))

// vou para a primeira linha
		UF2->(DbGoTop())

		While UF2->(!Eof())
			aadd(oGet5:acols,{"LBNO", UF2->UF2_NUM, UF2->UF2_VALOR, UF2->UF2_BENEF, UF2->UF2_HIST, UF2->(RecNo()), .F.})
			UF2->( dbskip() )
		EndDo

		// limpo os filtros da UF2
		UF2->(DbClearFilter())

	#ENDIF

	If Len(oGet5:acols) == 0
		Aadd(oGet5:acols, {"LBNO", space(tamsx3("UF2_NUM")[1]), 0 /*"UF2_VALOR"*/, space(tamsx3("UF2_BENEF")[1]), space(tamsx3("UF2_HIST")[1]), 0, .F.})
	EndIf

	oGet5:oBrowse:Refresh()

	nQtde  := 0
	nTotal := 0
	oQtde:Refresh()
	oTotal:Refresh()

	RestArea( aArea )

Return

//-------------------------------------------------------------------
Static Function TRANSFERIR(cOpeDes,cPDVDes)
	Local aArea := GetArea()
	Local lRet   := .T.
	Local lSrvPDV := SuperGetMV("MV_XSRVPDV",,.T.) //Servidor PDV
	Local nX
	Local lChTrOp := SuperGetMV("MV_XCHTROP",,.F.) //Controle de Cheque Troco por Operador (default .F.)

	If lChTrOp
		If Empty(cOpeDes)
			MsgAlert("Operador de destino é obrigatório!","Atenção")
			Return .F.
		EndIf
	Else
		If Empty(cPDVDes)
			MsgAlert("Numero de PDV de destino é obrigatório!","Atenção")
			Return .F.
		EndIf
	EndIf

	If lRet
		For nX:=1 to len(oGet5:aCols)
			cMarcacao := oGet5:aCols[nX][aScan(oGet5:aHeader,{|x| AllTrim(x[2])=="MARK"})]
			If !Empty(oGet5:aCols[nX,2]) .AND. !oGet5:aCols[nX,Len(oGet5:aCols[nX])] .AND. cMarcacao == "LBOK"

				nRecno := oGet5:aCols[nX][aScan(oGet5:aHeader,{|x| AllTrim(x[2])=="RECNO"})]

				dbselectarea("UF2")
				UF2->( dbgoto(nRecno) )

				UF2->(RecLock("UF2",.F.))
				If lChTrOp
					UF2->UF2_CODCX := cOpeDes
					UF2->UF2_PDV := ""
				Else
					UF2->UF2_CODCX := ""
					UF2->UF2_PDV := cPDVDes
				EndIf
				if UF2->(FieldPos("UF2_DTREM"))
					UF2->UF2_DTREM 	:= dDataBase
				endif
				UF2->(MsUnLock())
				If !lSrvPDV //se for na retaguarda replica o cadastro...
					U_UREPLICA("UF2", 1, UF2->(UF2_FILIAL+UF2_BANCO+UF2_AGENCI+UF2_CONTA+UF2_SEQUEN+UF2_NUM), "A")
				EndIf
			Endif
		Next nX

		MsgInfo("Remessa realizada com sucesso!","Atenção!")

		U_TRETR013(1) //impressao dos cheques transfereridos
		CARREGAR() //atualiza o cheques do caixa origem

	EndIf

	RestArea(aArea)

Return(lRet)

//-------------------------------------------------------------------
Static Function FMARTUDO(nOpc)
	Local nPosMark := aScan(oGet5:aHeader,{|x| AllTrim(x[2])=="MARK"})
	Local nX

	If len(oGet5:aCols) == 0
		Return()
	Endif

	For nX:=1 to len(oGet5:aCols)

		If nOpc == 1 //marca todos
			oGet5:aCols[nX][nPosMark] := "LBOK"
		ElseIf nOpc == 2 // desmarca todos
			oGet5:aCols[nX][nPosMark] := "LBNO"
		Else //inverte selecao
			If oGet5:aCols[nX][nPosMark] == "LBOK"
				oGet5:aCols[nX][nPosMark] := "LBNO"
			Else
				oGet5:aCols[nX][nPosMark] := "LBOK"
			EndIf
		EndIf

	Next nX

	oGet5:oBrowse:REFRESH()
	Refresh5()

Return

//-------------------------------------------------------------------
Static Function COMP11STRU( cCampo )
	Local lRet := .T.
	If AllTrim(cCampo) == 'UF2_BANCO' .or. ;
			AllTrim(cCampo) == 'UF2_AGENCI' .or. ;
			AllTrim(cCampo) == 'UF2_CONTA'
		lRet := .F.
	EndIf
Return lRet

//-------------------------------------------------------------------
Static Function valcheque(cBanco,cAgencia,cConta,cNum)
	Local lRet := .T.
	Local oModel      := FWModelActive()
	Local oModelUF2   := oModel:GetModel( 'UF2DETAIL' )
	Local nI          := 0
	Local aSaveLines  := FWSaveRows()

	dbselectarea("UF2")
	UF2->(dbsetorder(2)) //UF2_FILIAL+UF2_BANCO+UF2_AGENCI+UF2_CONTA+UF2_NUM
	if UF2->(dbseek(xFilial("UF2")+cBanco+cAgencia+cConta+cNum))
		lRet := .F.
	else
		For nI := 1 To oModelUF2:Length()
			oModelUF2:GoLine( nI )
			If !oModelUF2:IsDeleted() .and. alltrim(oModelUF2:GetValue( 'UF2_NUM' )) == alltrim(cNum)
				lRet := .F.
				Exit
			EndIf
		Next
		FWRestRows( aSaveLines )
	endif

Return lRet

