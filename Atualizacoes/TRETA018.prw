#INCLUDE 'PROTHEUS.CH'
#INCLUDE 'FWMVCDEF.CH'
#INCLUDE "rwmake.ch"
#INCLUDE "topconn.ch"

/*/{Protheus.doc} TRETA018
Cadastro de Operadora POS x Layout

@author Dainlo Brito
@since 18/06/2014
@version 1.0
@return Nil
@type function
/*/
User Function TRETA018()

	Local oBrowse

	DbSelectArea('U98')
	DbSelectArea('U99')

	oBrowse := FWmBrowse():New()
	oBrowse:SetAlias( 'U98' )
	oBrowse:SetDescription( 'Layout de Importação' )
	oBrowse:Activate()

Return

//-------------------------------------------------------------------
Static Function MenuDef()

	Local aRotina := {}

	ADD OPTION aRotina TITLE 'Visualizar'      ACTION 'VIEWDEF.TRETA018' OPERATION 2 ACCESS 0
	ADD OPTION aRotina TITLE 'Incluir'         ACTION 'VIEWDEF.TRETA018' OPERATION 3 ACCESS 0
	ADD OPTION aRotina TITLE 'Alterar'         ACTION 'VIEWDEF.TRETA018' OPERATION 4 ACCESS 0
	ADD OPTION aRotina TITLE 'Excluir'         ACTION 'VIEWDEF.TRETA018' OPERATION 5 ACCESS 0
	ADD OPTION aRotina TITLE 'Imprimir'        ACTION 'VIEWDEF.TRETA018' OPERATION 8 ACCESS 0
	ADD OPTION aRotina TITLE 'Copiar'          ACTION 'VIEWDEF.TRETA018' OPERATION 9 ACCESS 0

Return aRotina

//-------------------------------------------------------------------
Static Function ModelDef()

	// Cria a estrutura a ser usada no Modelo de Dados
	Local oStruU98  := FWFormStruct( 1, 'U98', /*bAvalCampo*/,/*lViewUsado*/ )
	Local oStruU99 := FWFormStruct( 1, 'U99', /*bAvalCampo*/,/*lViewUsado*/ )
	Local oModel

	// Cria o objeto do Modelo de Dados
	oModel := MPFormModel():New('TRETM018', /*bPreValidacao*/, /*bPosValidacao*/, /*bCommit*/, /*bCancel*/ )

	// Adiciona ao modelo uma estrutura de formul·rio de ediÁ?o por campo
	oModel:AddFields( 'U98MASTER', /*cOwner*/, oStruU98, /*bPreValidacao*/, /*bPosValidacao*/, /*bCarga*/ )

	// Adiciona a chave primaria da tabela principal
	oModel:SetPrimaryKey({ "U98_FILIAL" , "U98_OPERAD", "U98_CODIGO" })

	// Adiciona ao modelo uma componente de grid Credito
	oModel:AddGrid( 'U99DETAIL', 'U98MASTER', oStruU99 , /*bLinePre*/, /*bLinePost*/, /*bPreVal*/, /*bPosVal*/, /*BLoad*/ )

	// Faz relacionamento entre os componentes do model
	oModel:SetRelation( 'U99DETAIL', { {'U99_FILIAL', 'xFilial( "U99" )'}, {'U99_OPERAD', 'U98_OPERAD'}, {"U99_CODIGO", "U98_CODIGO"} }, U99->( IndexKey( 1 ) ) )

	// Liga o controle de nao repeticao de linha
	oModel:GetModel( 'U99DETAIL' ):SetUniqueLine( { 'U99_UTILIZ', 'U99_TIPPOS', 'U99_COLUNA', 'U99_POSINI', 'U99_TAMANH' } ) // 'U99_ITEM',

	// Adiciona a descricao do Modelo de Dados
	oModel:SetDescription( 'Modelo de Dados de Layout Operadora.' )

	// Adiciona a descrição dos Componentes do Modelo de Dados
	oModel:GetModel( 'U98MASTER' ):SetDescription( 'Dados da Operadora.' )
	oModel:GetModel( 'U99DETAIL' ):SetDescription( 'Layout de Importação' )

Return oModel


//-------------------------------------------------------------------
Static Function ViewDef()

	// Cria um objeto de Modelo de Dados baseado no ModelDef do fonte informado
	Local oModel   := FWLoadModel( 'TRETA018' )
	Local oView
	Local oCalc1

	// Cria a estrutura a ser usada na View
	Local oStruU98 := FWFormStruct( 2, 'U98' )
	Local oStruU99 := FWFormStruct( 2, 'U99' )

	// Remove campos da estrutura
	oStruU99:RemoveField( 'U99_OPERAD' )
	oStruU99:RemoveField( 'U99_CODIGO' )

	// Cria o objeto de View
	oView := FWFormView():New()

	// Define qual o Modelo de dados ser· utilizado
	oView:SetModel( oModel )

	//Adiciona no nosso View um controle do tipo FormFields(antiga enchoice)
	oView:AddField( 'VIEW_U98', oStruU98, 'U98MASTER' )

	//Adiciona no nosso View um controle do tipo Grid (antiga Getdados)
	oView:AddGrid( 'VIEW_U99', oStruU99, 'U99DETAIL' )

	// Define campos que terao Auto Incremento
	oView:AddIncrementField( 'VIEW_U99', 'U99_ITEM' )

	// Cria um "box" horizontal para receber cada elemento da view
	oView:CreateHorizontalBox( 'SUPERIOR'	, 30 )
	oView:CreateHorizontalBox( 'INFERIOR'  	, 70 )

	// Relaciona o identificador (ID) da View com o "box" para exibição
	oView:SetOwnerView( 'VIEW_U98' , 'SUPERIOR' )
	oView:SetOwnerView( 'VIEW_U99' , 'INFERIOR' )

	// titulo dos componentes
	oView:EnableTitleView('VIEW_U98' ,/*'cabecalho'*/)
	oView:EnableTitleView('VIEW_U99' , /*'item'*/)

Return oView

// Validacao do campo U98_OPERAD 
User Function TR18VlRD(cOperad)

	Local lRet 	:= .F.
	Local cMsg	:= ""
					
	dbSelectArea("MDE")
	MDE->(dbSetOrder(1)) //MDE_FILIAL+MDE_CODIGO
	If MDE->(dbSeek(xFilial("MDE")+cOperad ))
		//Verifica se eh um registro do tipo "REDE"
		While MDE->(!EoF()) .And. MDE->MDE_FILIAL+MDE->MDE_CODIGO == xFilial("MDE")+cOperad
			If MDE->MDE_TIPO == "RD" //RD=Rede
				lRet := .T.
				Exit
			EndIf
			MDE->(DbSkip())
		End
		
		If !lRet
			cMsg := "Este não é um código relacionado ao tipo REDE."
		EndIf
	Else
		cMsg := "O código informado não existe."
	EndIf

	If !lRet
		Help( " ", 1, "Help",, cMsg, 1, 0 )
	EndIf

Return lRet