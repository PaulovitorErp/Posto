#INCLUDE 'totvs.CH'
#INCLUDE 'FWMVCDEF.CH'

/*/{Protheus.doc} TRETA021
Cadastro de Negociação de Pagamento: Forma de Pagto x Cond de Pagto

@author Pablo Cavalcante
@since 24/04/2014
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
User Function TRETA021()
	Local oBrowse

	oBrowse := FWmBrowse():New()
	oBrowse:SetAlias( 'U44' )
	oBrowse:SetDescription( 'Negociação de Pagamento' )
	oBrowse:Activate()

Return NIL

//-------------------------------------------------------------------
/*/{Protheus.doc} MenuDef
description
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function MenuDef()
	Local aRotina := {}

	ADD OPTION aRotina Title 'Visualizar' 	Action 'VIEWDEF.TRETA021' 	OPERATION 2 ACCESS 0
	ADD OPTION aRotina Title 'Incluir'    	Action 'VIEWDEF.TRETA021' 	OPERATION 3 ACCESS 0
	ADD OPTION aRotina Title 'Alterar'    	Action 'VIEWDEF.TRETA021' 	OPERATION 4 ACCESS 0
	ADD OPTION aRotina Title 'Excluir'    	Action 'VIEWDEF.TRETA021' 	OPERATION 5 ACCESS 0
	ADD OPTION aRotina Title 'Imprimir'   	Action 'VIEWDEF.TRETA021' 	OPERATION 8 ACCESS 0
	if !empty(xFilial("U44"))
		ADD OPTION aRotina Title 'Replicar'   	Action 'U_TRET021A' 		OPERATION 9 ACCESS 0
	endif
	//ADD OPTION aRotina Title 'Copiar'     Action 'VIEWDEF.TRETA021' OPERATION 9 ACCESS 0

Return aRotina

//-------------------------------------------------------------------
/*/{Protheus.doc} ModelDef
description
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function ModelDef()
	Local oStruU44 := FWFormStruct( 1, 'U44', /*bAvalCampo*/,/*lViewUsado*/ )

	oStruU44:RemoveField( 'U44_FILIAL' )
	//nao permitir alterar campos chave depois de ja gravado
	oStruU44:SetProperty("U44_FORMPG", MODEL_FIELD_WHEN, {|oMdl, cFld| INCLUI })
	oStruU44:SetProperty("U44_CONDPG", MODEL_FIELD_WHEN, {|oMdl, cFld| INCLUI })

	oModel := MPFormModel():New( 'TRETM021', /*bPreValidacao*/, /*bPosValidacao*/, /*bCommit*/, /*bCancel*/ )

	// Adiciona ao modelo uma estrutura de formulário de edição por campo
	oModel:AddFields( 'U44MASTER', /*cOwner*/, oStruU44, /*bPreValidacao*/, /*bPosValidacao*/, /*bCarga*/ )

	// Adiciona a chave primaria da tabela principal
	oModel:SetPrimaryKey({ "U44_FILIAL" , "U44_FORMPG", "U44_CONDPG" })

	// Adiciona a descricao do Modelo de Dados
	oModel:SetDescription( 'Forma de Pagamento x Condição de Pagamento' )

	// Adiciona a descricao do Componente do Modelo de Dados
	oModel:GetModel( 'U44MASTER' ):SetDescription( 'Forma de Pagamento x Condição de Pagamento' )

	// Liga a validação da ativacao do Modelo de Dados
	//oModel:SetVldActive( { | oModel | COMP012ACT( oModel ) } )

Return oModel

//-------------------------------------------------------------------
/*/{Protheus.doc} ViewDef
description
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function ViewDef()
// Cria um objeto de Modelo de Dados baseado no ModelDef do fonte informado
	Local oModel   := FWLoadModel( 'TRETA021' )
// Cria a estrutura a ser usada na View
	Local oStruU44 := FWFormStruct( 2, 'U44' )
	Local oView

	// Cria o objeto de View
	oView := FWFormView():New()

	// Define qual o Modelo de dados será utilizado
	oView:SetModel( oModel )

	//Adiciona no nosso View um controle do tipo FormFields(antiga enchoice)
	oView:AddField( 'VIEW_U44', oStruU44, 'U44MASTER' )

	// Criar um "box" horizontal para receber algum elemento da view
	oView:CreateHorizontalBox( 'TELA' , 100 )

	// Relaciona o ID da View com o "box" para exibicao
	oView:SetOwnerView( 'VIEW_U44', 'TELA' )

Return oView

//-------------------------------------------------------------------
/*/{Protheus.doc} TRET021A
Função que reaplica a negociação de pagamento de uma filial para as 
filiais selecionadas no GRID 
@author  Henrique
@since   02/04/2015 
@version P12
/*/
//-------------------------------------------------------------------
User Function TRET021A()
	Local btnCanc
	Local btnConf
	Local lblCondPgto
	Local lblFilial
	Local lblFil2
	Local cblFil2 := FWFilialName()    //busca o nome da filial
	Local lblFormPgto
	Local txtCondPgto
	Local cxtCondPgto := U44->U44_CONDPG
	Local txtFilial
//Local cFilName := FWFilialName()  //busca o nome da filial
	Local cxtFilial := U44->U44_FILIAL
	Local txtFormPgto
	Local cxtFormPgto := U44->U44_FORMPG

//Local cQry			:= ""
	Local aInf			:= {}
	Local aCampos		:= {{"OK","C",002,0},{"COL1","C",004,0},{"COL2","C",040,0},{"COL3","C",040,0}}
	Local aCampos2		:= {{"OK","","",""},{"COL1","","Código",""},{"COL2","","Filial",""},{"COL3","","Nome",""}}
	Local nPosIt		:= 0
	Local _cSep
	Local _cInf
	Local nI

	Default _cSep		:= "/" //separador de retorno
	aInf				:= IIF(!Empty(_cInf),StrTokArr(AllTrim(StrTran(_cInf,CRLF,"")),_cSep),{})

	Private oSay1, oSay2, oSay3
	Private aDados		:= {}
	Private cRet		:= ""
	Private oTempTable as object

	Private oDlg
	Private oMark
	Private cMarca	 	:= "mk"
	Private lImpFechar	:= .F.

	Private nContSel	:= 0
//Private QRYAUX
	Private TRBAUX
	Private cInf := _cInf
	Private FilGRID := "" //filial no grid

	DbSelectArea("SM0")
	nRec := SM0->(Recno())
	SM0->(dbGoTop())
	While SM0->(!Eof())
		If (SM0->M0_CODFIL != cxtFilial)
			If (SM0->M0_CODIGO == cEmpAnt)
				//If (SM0->D_E_L_E_T_<> '*')
					aAdd(aDados,{&("SM0->M0_CODFIL"),&("SM0->M0_FILIAL"),&("SM0->M0_NOME"),""})
				//EndIf
			EndIf
		EndIf
		SM0->(DbSkip())
	EndDo
	//libero registro
	//SM0->(dbCloseArea()) COMENTEI ESSA LINHA POIS NÃO PODE FECHAR ESSA TABELA DE FILIAIS
	SM0->(dbGoTo(nRec))
	
	//cria a tabela temporaria
	oTempTable := FWTemporaryTable():New("TRBAUX")
	oTempTable:SetFields(aCampos)
	oTempTable:Create()

	DbSelectArea("TRBAUX")

	If Len(aDados) > 0
		For nI := 1 to Len(aDados)
			TRBAUX->(RecLock("TRBAUX",.T.))
			If Len(aInf) > 0
				nPosIt := aScan(aInf,{|x| AllTrim(x) == AllTrim(aDados[nI][1])})
				If nPosIt > 0
					TRBAUX->OK := "mk"
					nContSel++
				Else
					TRBAUX->OK := "  "
				EndIf
			Else
				TRBAUX->OK := "  "
			EndIf

			TRBAUX->COL1 := aDados[nI][1]  //CODIGO DA FILIAL
			TRBAUX->COL2 := aDados[nI][2]  //NOME DA FILIAL
			TRBAUX->COL3 := aDados[nI][3]  //FORMA DE PAGAMENTO
			TRBAUX->(MsUnlock())

		Next
	Else
		TRBAUX->(RecLock("TRBAUX",.T.))
		TRBAUX->OK		:= "  "
		TRBAUX->COL1	:= Space(4)		//CODIGO
		TRBAUX->COL2 	:= Space(40)    //FILIAL
		TRBAUX->COL3 	:= Space(40)    //NOME
		TRBAUX->(MsUnlock())
	EndIf

	TRBAUX->(DbGoTop())   //POSICIONA O GRID NA PRIMEIRA LINHA


	DEFINE MSDIALOG oDlg TITLE "Reaplicação de Negociação de Pagamento" FROM 000, 000  TO 500, 750 COLORS 0, 16777215 PIXEL

	@ 010, 008 SAY lblFilial PROMPT "Filial:" SIZE 023, 009 OF oDlg COLORS 0, 16777215 PIXEL
	@ 010, 197 SAY lblFormPgto PROMPT "Forma Pgto:" SIZE 032, 009 OF oDlg COLORS 0, 16777215 PIXEL
	@ 010, 286 SAY lblCondPgto PROMPT "Cond Pgto:" SIZE 032, 009 OF oDlg COLORS 0, 16777215 PIXEL
	@ 009, 031 MSGET txtFilial VAR cxtFilial SIZE 150, 010 WHEN .F. OF oDlg COLORS 0, 16777215 PIXEL
	@ 009, 231 MSGET txtFormPgto VAR cxtFormPgto SIZE 038, 010 WHEN .F. OF oDlg COLORS 0, 16777215 PIXEL
	@ 009, 320 MSGET txtCondPgto VAR cxtCondPgto SIZE 040, 010 WHEN .F. OF oDlg COLORS 0, 16777215 PIXEL
	//fMSNewGe1()
	//Browse  -  GRID
	oMark := MsSelect():New("TRBAUX","OK","",aCampos2,,@cMarca,{030,005,220,370})
	//oMark := MsSelect():New("TRBAUX","OK","",aCampos2,,@cMarca,{038,005,100,100})
	oMark:bMark 				:= {||MarcaIt()}
	oMark:oBrowse:LCANALLMARK 	:= .T.
	oMark:oBrowse:LHASMARK    	:= .T.
	oMark:oBrowse:bAllMark 		:= {||MarcaT()}

	@ 235, 005 SAY oSay2 PROMPT "Total de registros selecionados:" SIZE 200, 007 OF oDlg COLORS 0, 16777215 PIXEL
	@ 235, 090 SAY oSay3 PROMPT cValToChar(nContSel) SIZE 040, 007 OF oDlg COLORS 0, 16777215 PIXEL

	@ 230, 280 BUTTON btnConf PROMPT "Confirmar" SIZE 039, 013 OF oDlg ACTION MsAguarde({|| ConfReapli()}, "Aguarde","Reaplicando informações...",.F.) PIXEL
	@ 230, 330 BUTTON btnCanc PROMPT "Cancelar" SIZE 039, 013 OF oDlg ACTION Fech001() PIXEL
	@ 009, 061 MSGET lblFil2 VAR cblFil2 SIZE 129, 010 WHEN .F. OF oDlg COLORS 0, 16777215 PIXEL

	ACTIVATE MSDIALOG oDlg CENTERED VALID lImpFechar //impede o usuario fechar a janela atraves do [X]

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} Fech001
description
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function Fech001()

	lImpFechar := .T.

	If Select("TRBAUX") > 0   //TRBAUX
		TRBAUX->(DbCloseArea())
	EndIf

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Apagando arquivo temporario                                         ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	oTempTable:Delete()

	oDlg:End()

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} MarcaIt
description
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function MarcaIt()

	If TRBAUX->OK == "mk"
		nContSel++
	Else
		--nContSel
	EndIf

	oSay3:Refresh()

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} MarcaT
description
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function MarcaT()

	Local lMarca 	:= .F.
	Local lNMARCA 	:= .F.

	nContSel := 0

	TRBAUX->(dbGoTop())

	While TRBAUX->(!EOF())
		If TRBAUX->OK == "mk" .And. !lMarca
			RecLock("TRBAUX",.F.)
			TRBAUX->OK := "  "
			TRBAUX->(MsUnlock())
			lNMarca := .T.
		Else
			If !lNMarca
				RecLock("TRBAUX",.F.)
				TRBAUX->OK := "mk"
				TRBAUX->(MsUnlock())
				nContSel++
				lMarca := .T.
			EndIf
		EndIf

		TRBAUX->(dbSkip())
	EndDo

	TRBAUX->(dbGoTop())

	oSay3:Refresh()

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} ConfReapli
Função que é chamada ao clicar no botão "Replicar" na função TRET021A().
Esta função Reaplica as informacoes de forma de pagamento de uma
filial pre-selecionada  para uma ou mais filiais selecionadas
pelo cliente.

@author  Henrique Botelho Gomes
@since   02/04/2015 
@version P12
/*/
//-------------------------------------------------------------------
Static Function ConfReapli()

	Local aAuxClient := {}  //Array auxiliar que guarda os dados do cliente principal selecionado
	Local contErro := 0

//SALVA EM UM ARRAY OS DADOS DA FILIAL PAI SELECIONADA A SER REAPLICADO PARA OUTRAS FILIAIS
	AAdd(aAuxClient,U44->U44_FILIAL)
	AAdd(aAuxClient,U44->U44_FORMPG)
	AAdd(aAuxClient,U44->U44_CONDPG)
	AAdd(aAuxClient,U44->U44_DESCRI)
	AAdd(aAuxClient,U44->U44_PADRAO)
	AAdd(aAuxClient,U44->U44_PERMAX)
	AAdd(aAuxClient,U44->U44_VLRMAX)
	AAdd(aAuxClient,U44->U44_PERMTR)
	AAdd(aAuxClient,U44->U44_PERCHT)
	AAdd(aAuxClient,U44->U44_PERVHA)
	AAdd(aAuxClient,U44->U44_MSEXP)
	AAdd(aAuxClient,U44->U44_HREXP)
	AAdd(aAuxClient,U44->U44_TXPERD)
	AAdd(aAuxClient,U44->U44_TXRETO)
	AAdd(aAuxClient,U44->U44_PFID) //TODO REMOVER
	AAdd(aAuxClient,U44->U44_CODANT) //TODO remover 
	AAdd(aAuxClient,U44->U44_DESANT) //TODO remover

	TRBAUX->(dbGoTop())

	While TRBAUX->(!EOF())

		If TRBAUX->OK == "mk"   //Se linha da grid selecionada
			//atualiza no registro posicionado o segundo browser as informações do cliente selecionado no primeiro browser
			U44->(dbSetOrder(1))

			If U44->(dbSeek(xFilial("U44") + U44->U44_FORMPG + U44->U44_CONDPG))     // Busca exata, se verdadeiro, entra
				RecLock("U44", .T.)  //F-> altera.  T-> inclui

				//U88->U88_CLIENT := TRBAUX->COL1
				//U88->U88_LOJA 	:= TRBAUX->COL2
				//U88->U88_NOME 	:= TRBAUX->COL3
				//Mantem somente o número da filial selecionada como pai, e inclui os outros dados
				U44->U44_FILIAL := TRBAUX->COL1
				U44->U44_FORMPG := aAuxClient[2]
				U44->U44_CONDPG := aAuxClient[3]
				U44->U44_DESCRI := aAuxClient[4]
				U44->U44_PADRAO := aAuxClient[5]
				U44->U44_PERMAX := aAuxClient[6]
				U44->U44_VLRMAX := aAuxClient[7]
				U44->U44_PERMTR := aAuxClient[8]
				U44->U44_PERCHT := aAuxClient[9]
				U44->U44_PERVHA := aAuxClient[10]
				U44->U44_MSEXP 	:= aAuxClient[11]
				U44->U44_HREXP 	:= aAuxClient[12]
				U44->U44_TXPERD := aAuxClient[13]
				U44->U44_TXRETO := aAuxClient[14]
				U44->U44_PFID 	:= aAuxClient[15] //TODO REMOVER
				U44->U44_CODANT	:= aAuxClient[16]
				U44->U44_DESANT	:= aAuxClient[17]

				U44->(MsUnLock()) // Destrava o registro

				//Função que grava o flag para integração das bases POSTO X RETAGUARDA
				U_UREPLICA("U44",1,xFilial("U44") + U44->U44_FORMPG + U44->U44_CONDPG,"I")

			Else //se não foi localizado o registro, então gera erro
				contErro++
			EndIf

		Else  //Se linha da grid NÃO selecionada
			//não faz nada
		EndIf

		TRBAUX->(dbSkip()) //AVANÇA UM REGISTRO
	EndDo  // End of While TRBAUX->(!EOF())

	//Emite mensagem de erro ou não
	If(contErro > 0)
		Help(,,"Atenção",,"Não foi possível replicar as informações.",1,0,,,,,,{""})
	Else
		Help(,,"Sucesso",,"Informações reaplicadas com sucesso.",1,0,,,,,,{""})
	EndIf

	Fech001()

Return
