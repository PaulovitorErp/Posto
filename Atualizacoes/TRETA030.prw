#include 'Protheus.ch'
#include 'FWMVCDef.ch'
#include 'parmtype.ch'

Static cTitulo  := "Tabela de Preço Base"

/*/{Protheus.doc} TRETA030
Cadastro de Tabela de Preço Base

@author pablo
@since 18/04/2019
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
User Function TRETA030()

Local aArea   := GetArea()
Local oBrowse
Local cFunBkp := FunName()
	
	SetFunName("TRETA030")
	
	oBrowse := FWMBrowse():New()
	oBrowse:SetAlias("U0B")
	oBrowse:SetDescription(cTitulo)
	oBrowse:Activate()	
	
	SetFunName(cFunBkp)
	RestArea(aArea)
	
Return Nil

/*---------------------------------------------------------------------*
 | Func:  MenuDef                                                      |
 | Autor: Pablo Nunes                                                  |
 | Data:  14/01/2017                                                   |
 | Desc:  Criação do menu MVC                                          |
 *---------------------------------------------------------------------*/

Static Function MenuDef()

	Local aRot := {}
	
	//Adicionando opções
	ADD OPTION aRot TITLE 'Visualizar' ACTION 'VIEWDEF.TRETA030' OPERATION MODEL_OPERATION_VIEW   ACCESS 0 //OPERATION 1
	ADD OPTION aRot TITLE 'Incluir'    ACTION 'VIEWDEF.TRETA030' OPERATION MODEL_OPERATION_INSERT ACCESS 0 //OPERATION 3
	ADD OPTION aRot TITLE 'Alterar'    ACTION 'VIEWDEF.TRETA030' OPERATION MODEL_OPERATION_UPDATE ACCESS 0 //OPERATION 4
	ADD OPTION aRot TITLE 'Excluir'    ACTION 'VIEWDEF.TRETA030' OPERATION MODEL_OPERATION_DELETE ACCESS 0 //OPERATION 5

	//PE para add nova opções
	If ExistBlock("TRA030MN")
		aRot := ExecBlock("TRA030MN",.F.,.F.,aRot)
	Endif
	
Return aRot

/*---------------------------------------------------------------------*
 | Func:  ModelDef                                                     |
 | Autor: Pablo Nunes                                                  |
 | Data:  14/01/2017                                                   |
 | Desc:  Criação do modelo de dados MVC                               |
 *---------------------------------------------------------------------*/

Static Function ModelDef()

	Local oModel   := Nil
	Local oStPai   := FWFormStruct(1, 'U0B')
	Local oStFilho := FWFormStruct(1, 'U0C')
	Local bVldPos  := {|| U_TRET030A()}
	Local bVldCom  := {|| U_TRET030B()}
	Local aU0CRel  := {}
	
	//Setando as propriedades na grid, o inicializador da Filial e Tabela, para não dar mensagem de coluna vazia
	oStFilho:SetProperty('U0C_FILIAL', MODEL_FIELD_INIT, FwBuildFeature(STRUCT_FEATURE_INIPAD, '"*"'))
	oStFilho:SetProperty('U0C_PRODUT', MODEL_FIELD_INIT, FwBuildFeature(STRUCT_FEATURE_INIPAD, '"*"'))
	
	oStFilho:SetProperty('U0C_FORPAG', MODEL_FIELD_WHEN, { |oMdl| .F.} )
	oStFilho:SetProperty('U0C_DESFOR', MODEL_FIELD_WHEN, { |oMdl| .F.} )
	oStFilho:SetProperty('U0C_CONDPG', MODEL_FIELD_WHEN, { |oMdl| .F.} )
	oStFilho:SetProperty('U0C_DESCND', MODEL_FIELD_WHEN, { |oMdl| .F.} )
	oStFilho:SetProperty('U0C_DESNPG', MODEL_FIELD_WHEN, { |oMdl| .F.} )
	oStFilho:SetProperty('U0C_ADMFIN', MODEL_FIELD_WHEN, { |oMdl| .F.} )
	oStFilho:SetProperty('U0C_DESADM', MODEL_FIELD_WHEN, { |oMdl| .F.} )
	//oStFilho:SetProperty('U0C_PRCOLD', MODEL_FIELD_WHEN, { |oMdl| .F.} )
	
	oStFilho:SetProperty( "U0C_PRCBAS", MODEL_FIELD_VALID, {|| U_TRETA30C()} )
	oStFilho:SetProperty( "U0C_DTINIC", MODEL_FIELD_VALID, {|| U_TRETA30C()} )
	oStFilho:SetProperty( "U0C_HRINIC", MODEL_FIELD_VALID, {|| U_TRETA30C()} )
	
	//Criando o FormModel, adicionando o Cabeçalho e Grid
	oModel := MPFormModel():New( 'TRETM030', , bVldPos, /*bVldCom*/ ) 
	oModel:AddFields('U0BMASTER',/*cOwner*/,oStPai)
	oModel:AddGrid('U0CDETAIL','U0BMASTER', oStFilho)
	
	//Adiciona o relacionamento de Filho, Pai
	aAdd(aU0CRel, {'U0C_FILIAL', 'xFilial("U0C")'} )
	aAdd(aU0CRel, {'U0C_PRODUT', 'U0B_PRODUT'} ) 
	
	//Criando o relacionamento
	oModel:SetRelation('U0CDETAIL', aU0CRel, U0C->(IndexKey(1))) //U0C_FILIAL+U0C_PRODUT+U0C_FORPAG+U0C_CONDPG+U0C_ADMFIN
	
	//Setando o campo único da grid para não ter repetição
	oModel:GetModel('U0CDETAIL'):SetUniqueLine({"U0C_FORPAG", "U0C_CONDPG", "U0C_ADMFIN"})
	
	//Setando outras informações do Modelo de Dados
	oModel:SetDescription("Modelo de Dados "+cTitulo)
	oModel:SetPrimaryKey({})
	oModel:GetModel("U0BMASTER"):SetDescription("Formulário do Cadastro "+cTitulo)
	
	//oModel:GetModel("U0CDETAIL"):SetNoDeleteLine(.T.) 
    //oModel:GetModel("U0CDETAIL"):SetNoInsertLine(.T.) 
    //oModel:GetModel("U0CDETAIL"):SetNoUpdateLine(.T.) 
    
    oModel:SetActivate({ |oModel| CarregaTab(oModel)})
	
Return oModel

/*---------------------------------------------------------------------*
 | Func:  ViewDef                                                      |
 | Autor: Pablo Nunes                                                  |
 | Data:  14/01/2017                                                   |
 | Desc:  Criação da visão MVC                                         |
 *---------------------------------------------------------------------*/

Static Function ViewDef()

	Local oModel     := FWLoadModel("TRETA030")
	Local oStPai     := FWFormStruct(2, 'U0B')
	Local oStFilho   := FWFormStruct(2, 'U0C')
	Local oView      := Nil
	
	//Criando a view que será o retorno da função e setando o modelo da rotina
	oView := FWFormView():New()
	oView:SetModel(oModel)
	
	oView:AddField('VIEW_CAB', oStPai  , "U0BMASTER")
	oView:AddGrid('VIEW_U0C' , oStFilho, 'U0CDETAIL')
	
	//Setando o dimensionamento de tamanho
	oView:CreateHorizontalBox('CABEC',15)
	oView:CreateHorizontalBox('GRID', 85)
	
	//Amarrando a view com as box
	oView:SetOwnerView('VIEW_CAB','CABEC')
	oView:SetOwnerView('VIEW_U0C','GRID')
	
	//Habilitando título
	oView:EnableTitleView('VIEW_CAB','Produto')
	oView:EnableTitleView('VIEW_U0C','Tabela de Preço Base')
	
	//Tratativa padrão para fechar a tela
	oView:SetCloseOnOk({||.T.})
	
	//Remove os campos de Filial e Tabela da Grid
	oStPai:RemoveField('U0B_FILIAL')
	oStFilho:RemoveField('U0C_FILIAL')
	oStFilho:RemoveField('U0C_PRODUT')
	oStFilho:RemoveField('U0C_DESPRO')
	oStFilho:RemoveField('U0C_DESFOR')
	oStFilho:RemoveField('U0C_DESCND')
	
Return oView

/*/{Protheus.doc} TRET030A
Função chamada na validação do botão Confirmar, para verificar se já existe a tabela digitada na inclusão

@type function
@author Atilio
@since 14/01/2017
@version 1.0
	@return lRet, .T. se pode prosseguir e .F. se deve barrar
/*/

User Function TRET030A()

	Local aArea      := GetArea()
	Local lRet       := .T.
	Local oModelDad  := FWModelActive()
	Local cFilU0B    := oModelDad:GetValue('U0BMASTER', 'U0B_FILIAL')
	Local cCodigo    := oModelDad:GetValue('U0BMASTER', 'U0B_PRODUT')
	Local nOpc       := oModelDad:GetOperation()
	
	//Se for Inclusão
	If nOpc = MODEL_OPERATION_INSERT
		DbSelectArea('U0B')
		U0B->(DbSetOrder(1)) //U0B_FILIAL+U0B_PRODUT
		//Se conseguir posicionar, tabela já existe
		If U0B->(DbSeek(cFilU0B + cCodigo))
			Help(, , "HELP", , "Já existe Tabela de Preço Base para este produto!", 1, 0, , , , , , {"Favor localizar o produto e realizar a atualização."+ CRLF +"Opção: Alterar"}) 
			lRet := .F.
		EndIf
	EndIf
	
	RestArea(aArea)
	
Return lRet

/*/{Protheus.doc} TRET030B
Função desenvolvida para salvar os dados do Modelo 2

@type function
@author Atilio
@since 14/01/2017
@version 1.0
/*/

User Function TRET030B()

	Local aArea      := GetArea()
	Local lRet       := .T.
	Local oModelDad  := FWModelActive()
	Local cFilU0B    := oModelDad:GetValue('U0BMASTER', 'U0B_FILIAL')
	Local cCodigo    := SubStr(oModelDad:GetValue('U0BMASTER', 'U0B_PRODUT'), 1, TamSX3('U0B_PRODUT')[01])
	
	Local nOpc       := oModelDad:GetOperation()
	Local oModelGrid := oModelDad:GetModel('U0CDETAIL')
	Local nX     := 0
	
	DbSelectArea('U0C')
	U0C->(DbSetOrder(1)) //U0C_FILIAL+U0C_PRODUT+U0C_FORPAG+U0C_CONDPG+U0C_ADMFIN
	
	//Se for Inclusão
	If nOpc == MODEL_OPERATION_INSERT
		
		For nX := 1 To oModelGrid:Length()
		
			oModelGrid:Goline(nX) // posiciono na linha atual
		
			If !oModelGrid:IsDeleted(nX)
				RecLock('U0C', .T.)
					U0C_FILIAL := cFilU0B
					U0C_PRODUT := cCodigo
					U0C->U0C_FORPAG := oModelGrid:GetValue('U0C_FORPAG')
					U0C->U0C_CONDPG := oModelGrid:GetValue('U0C_CONDPG')
					U0C->U0C_ADMFIN := oModelGrid:GetValue('U0C_ADMFIN')
					U0C->U0C_PRCBAS := oModelGrid:GetValue('U0C_PRCBAS')
				U0C->(MsUnlock())
			EndIf
	
		Next nX
		
	//Se for Alteração
	ElseIf nOpc == MODEL_OPERATION_UPDATE
		
		//Percorre o acols
		For nX := 1 To oModelGrid:Length()
		
			oModelGrid:Goline(nX) // posiciono na linha atual
		
			//Se a linha estiver excluída
			If oModelGrid:IsDeleted(nX)
				//Se conseguir posicionar, exclui o registro 
				If U0C->(DbSeek( cFilU0B + cCodigo + oModelGrid:GetValue('U0C_FORPAG') + oModelGrid:GetValue('U0C_CONDPG') + oModelGrid:GetValue('U0C_ADMFIN') ))
					RecLock('U0C', .F.)
						DbDelete()
					U0C->(MsUnlock())
				EndIf
				
			Else
				//Se conseguir posicionar no registro, será alteração
				If U0C->(DbSeek( cFilU0B + cCodigo + oModelGrid:GetValue('U0C_FORPAG') + oModelGrid:GetValue('U0C_CONDPG') + oModelGrid:GetValue('U0C_ADMFIN') ))
					RecLock('U0C', .F.)
				
				//Senão, será inclusão
				Else
					RecLock('U0C', .T.)
					U0C->U0C_FILIAL := cFilU0B
					U0C->U0C_PRODUT := cCodigo
				EndIf
				
				U0C->U0C_PRCBAS := oModelGrid:GetValue('U0C_PRCBAS')
				U0C->(MsUnlock())
			EndIf
			
		Next
		
	//Se for Exclusão
	ElseIf nOpc == MODEL_OPERATION_DELETE
		
		//Se conseguir posicionar, exclui o registro
		If U0C->(DbSeek(cFilU0B + cCodigo))
			While U0C->(!Eof()) .and. U0C->(U0C_FILIAL+U0C_PRODUT) = (cFilU0B + cCodigo)
				RecLock('U0C', .F.)
					DbDelete()
				U0C->(MsUnlock())
				U0C->(DbSkip())
			EndDo
		EndIf
		
		//Percorre a grid
		For nX := 1 To oModelGrid:Length()
		
			oModelGrid:Goline(nX) // posiciono na linha atual
			
			//Se conseguir posicionar, exclui o registro
			If U0C->(DbSeek( cFilU0B + cCodigo + oModelGrid:GetValue('U0C_FORPAG') + oModelGrid:GetValue('U0C_CONDPG') + oModelGrid:GetValue('U0C_ADMFIN') ))
				RecLock('U0C', .F.)
					DbDelete()
				U0C->(MsUnlock())
			EndIf
			
		Next
		
	EndIf
	
	RestArea(aArea)
	
Return lRet


/*/{Protheus.doc} TRETA30C
Validação do campo: U0C_PRCBAS, U0C_DTINIC e U0C_HRINIC para gatilho para o campo U0C_PRCOLD

@author pablo
@since 29/05/2019
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
User Function TRETA30C()
Local oModelDad  := FWModelActive()
Local oModelGrid := oModelDad:GetModel('U0CDETAIL')
Local cFilU0B    := oModelDad:GetValue('U0BMASTER', 'U0B_FILIAL')
Local cCodigo    := SubStr(oModelDad:GetValue('U0BMASTER', 'U0B_PRODUT'), 1, TamSX3('U0B_PRODUT')[01])	

//If nOpc = MODEL_OPERATION_VIEW .or. nOpc = MODEL_OPERATION_DELETE
//	Return .T.
//EndIf

	U0C->(DbSetOrder(1)) //U0C_FILIAL+U0C_PRODUT+U0C_FORPAG+U0C_CONDPG+U0C_ADMFIN
	If U0C->(DbSeek( cFilU0B + cCodigo + oModelGrid:GetValue('U0C_FORPAG') + oModelGrid:GetValue('U0C_CONDPG') + oModelGrid:GetValue('U0C_ADMFIN') ))

		//If !Empty(DtoS(oModelGrid:GetValue("U0C_DTINIC"))) .and. !Empty(oModelGrid:GetValue("U0C_HRINIC")) .and. DtoS(oModelGrid:GetValue("U0C_DTINIC"))+oModelGrid:GetValue("U0C_HRINIC") > (DtoS(Date())+PadR(Time(),TamSx3("U0C_HRINIC")[01]))
		//	oModelGrid:LoadValue( 'U0C_PRCOLD', U0C->U0C_PRCBAS )
		//ElseIf Empty(DtoS(oModelGrid:GetValue("U0C_DTINIC"))) .and. Empty(oModelGrid:GetValue("U0C_HRINIC"))
		//	oModelGrid:LoadValue( 'U0C_PRCOLD', U0C->U0C_PRCBAS )
		//EndIf

		If "U0C_PRCBAS" $ AllTrim(ReadVar())
			oModelGrid:LoadValue( 'U0C_PRCOLD', U0C->U0C_PRCBAS )
		ElseIf "U0C_DTINIC" $ AllTrim(ReadVar())
			oModelGrid:LoadValue( 'U0C_PRCOLD', U0C->U0C_PRCBAS )
		ElseIf "U0C_HRINIC" $ AllTrim(ReadVar())
			oModelGrid:LoadValue( 'U0C_PRCOLD', U0C->U0C_PRCBAS )
		EndIf
		
	EndIf
	
Return .T.

/*/{Protheus.doc} CarregaTab
Carrega todos tipos de preço da tabela U0A

@author pablo
@since 18/04/2019
@version 1.0
@return ${return}, ${return_description}
@param oMdl, object, descricao
@type function
/*/
Static Function CarregaTab( oMdl )
Local aArea      := GetArea()

Local nLinhaU0C  := 0
Local nX		 := 0
Local oModelDad  := FWModelActive()
Local oModelGrid := oModelDad:GetModel('U0CDETAIL')
Local nOpc       := oModelDad:GetOperation()
Local cFilU0B    := oModelDad:GetValue('U0BMASTER', 'U0B_FILIAL')
Local cCodigo    := SubStr(oModelDad:GetValue('U0BMASTER', 'U0B_PRODUT'), 1, TamSX3('U0B_PRODUT')[01])
Local oView 	 := FWViewActive()

If nOpc = MODEL_OPERATION_VIEW .or. nOpc = MODEL_OPERATION_DELETE
	Return NIL
EndIf

U0A->(DbSetOrder(1)) //U0A_FILIAL+U0A_FORPAG+U0A_CONDPG+U0A_ADMFIN
U0C->(DbSetOrder(1)) //U0C_FILIAL+U0C_PRODUT+U0C_FORPAG+U0C_CONDPG+U0C_ADMFIN

oModelGrid:SetNoDeleteLine(.F.)
oModelGrid:SetNoInsertLine(.F.)
oModelGrid:SetNoUpdateLine(.F.)

If nOpc = MODEL_OPERATION_INSERT

	dbselectarea("U0A")
	U0A->(DbSetOrder(1)) //U0A_FILIAL+U0A_FORPAG+U0A_CONDPG+U0A_ADMFIN
	U0A->(DbSeek(xFilial("U0A")))
	While U0A->(!Eof()) .and. U0A->U0A_FILIAL = xFilial("U0A")
		
		If !oModelGrid:IsEmpty()
			oModelGrid:AddLine()
		EndIf
		
		oModelGrid:LoadValue( 'U0C_FORPAG', U0A->U0A_FORPAG )
		oModelGrid:LoadValue( 'U0C_DESFOR', SubStr(POSICIONE("SX5",1,XFILIAL("SX5")+'24'+U0A->U0A_FORPAG,"X5_DESCRI"),1,TamSX3("U0C_DESFOR")[1]) )
		oModelGrid:LoadValue( 'U0C_CONDPG', U0A->U0A_CONDPG )
		oModelGrid:LoadValue( 'U0C_DESCND', SubStr(POSICIONE("SE4",1,XFILIAL("SE4")+U0A->U0A_CONDPG,"E4_DESCRI"),1,TamSX3("U0C_DESCND")[1]) )
		oModelGrid:LoadValue( 'U0C_DESNPG', SubStr(POSICIONE("U44",1,XFILIAL("U44")+U0A->U0A_FORPAG+U0A->U0A_CONDPG,"U44_DESCRI"),1,TamSX3("U0C_DESNPG")[1]) )
		oModelGrid:LoadValue( 'U0C_ADMFIN', U0A->U0A_ADMFIN )
		oModelGrid:LoadValue( 'U0C_DESADM', SubStr(POSICIONE('SAE',1,XFILIAL('SAE')+U0A->U0A_ADMFIN,'AE_DESC'),1,TamSX3("U0C_DESADM")[1]) )
		
		If U0C->(DbSeek( cFilU0B + cCodigo + oModelGrid:GetValue('U0C_FORPAG') + oModelGrid:GetValue('U0C_CONDPG') + oModelGrid:GetValue('U0C_ADMFIN') ))
			oModelGrid:LoadValue( 'U0C_PRCBAS', U0C->U0C_PRCBAS )
		EndIf
		
		U0A->(DbSkip())
	EndDo
	
EndIf

If nOpc = MODEL_OPERATION_UPDATE
	
	//-- valida pelo U0A
	U0A->(DbSeek( xFilial("U0A")))
	While U0A->(!Eof()) .and. (U0A->U0A_FILIAL = xFilial("U0A"))
		
		If !oModelGrid:SeekLine({ ;
			{"U0C_FORPAG", U0A->U0A_FORPAG },;
			{"U0C_CONDPG", U0A->U0A_CONDPG },;
			{"U0C_ADMFIN", U0A->U0A_ADMFIN };
			})
		
			If !oModelGrid:IsEmpty()
				oModelGrid:AddLine()
			EndIf
			
			oModelGrid:LoadValue( 'U0C_FORPAG', U0A->U0A_FORPAG )
			oModelGrid:LoadValue( 'U0C_DESFOR', SubStr(POSICIONE("SX5",1,XFILIAL("SX5")+'24'+U0A->U0A_FORPAG,"X5_DESCRI"),1,TamSX3("U0C_DESFOR")[1]) )
			oModelGrid:LoadValue( 'U0C_CONDPG', U0A->U0A_CONDPG )
			oModelGrid:LoadValue( 'U0C_DESCND', SubStr(POSICIONE("SE4",1,XFILIAL("SE4")+U0A->U0A_CONDPG,"E4_DESCRI"),1,TamSX3("U0C_DESCND")[1]) )
			oModelGrid:LoadValue( 'U0C_DESNPG', SubStr(POSICIONE("U44",1,XFILIAL("U44")+U0A->U0A_FORPAG+U0A->U0A_CONDPG,"U44_DESCRI"),1,TamSX3("U0C_DESNPG")[1]) )
			oModelGrid:LoadValue( 'U0C_ADMFIN', U0A->U0A_ADMFIN )
			oModelGrid:LoadValue( 'U0C_DESADM', SubStr(POSICIONE('SAE',1,XFILIAL('SAE')+U0A->U0A_ADMFIN,'AE_DESC'),1,TamSX3("U0C_DESADM")[1]) )
			
			If U0C->(DbSeek( cFilU0B + cCodigo + oModelGrid:GetValue('U0C_FORPAG') + oModelGrid:GetValue('U0C_CONDPG') + oModelGrid:GetValue('U0C_ADMFIN') ))
				oModelGrid:LoadValue( 'U0C_PRCBAS', U0C->U0C_PRCBAS )
			EndIf
			
		EndIf
		
		U0A->(DbSkip())
	EndDo
	
	//-- valida pelo oModelGrid
	For nX := 1 To oModelGrid:Length()
		oModelGrid:Goline(nX)
		
		If !oModelGrid:IsDeleted(nX)
			If !U0A->(DbSeek( xFilial("U0A") + oModelGrid:GetValue('U0C_FORPAG') + oModelGrid:GetValue('U0C_CONDPG') + oModelGrid:GetValue('U0C_ADMFIN') ))
				oModelGrid:DeleteLine()
			EndIf
		EndIf
			
	Next nX

EndIf

oModelDad:GetModel("U0CDETAIL"):SetNoInsertLine()
//oModelDad:GetModel("U0CDETAIL"):SetNoUpdateLine()
oModelDad:GetModel("U0CDETAIL"):SetNoDeleteLine()

//oView:Refresh()

RestArea( aArea )

Return NIL
