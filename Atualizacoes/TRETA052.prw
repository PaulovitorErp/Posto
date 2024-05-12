#include 'protheus.ch'
#include 'parmtype.ch'
#INCLUDE 'FWMVCDEF.CH'

/*/{Protheus.doc} TRETA052

//Cadastro de Limite Cliente por Segmento

@author danilo
@since 01/08/2023
@version 1.0
@return Nil

@type function
/*/
User function TRETA052()

	Local oBrowse

	Private aRotina
	Private cCadastro := 'Limites Cliente por Segmento'

	DbSelectArea("SA1")
	DbSelectArea("UC4")

	oBrowse := FWmBrowse():New()
	oBrowse:SetAlias( 'SA1' )
	oBrowse:SetDescription( cCadastro )

	oBrowse:Activate()

Return

//-------------------------------------------------------------------
// Definicao do Menu
//-------------------------------------------------------------------
Static Function MenuDef()

	aRotina := {}

	ADD OPTION aRotina TITLE 'Visualizar'      ACTION 'VIEWDEF.TRETA052' OPERATION 2 ACCESS 0
	ADD OPTION aRotina TITLE 'Limites'         ACTION 'VIEWDEF.TRETA052' OPERATION 4 ACCESS 0

Return aRotina

//-------------------------------------------------------------------
// Define Modelo de Dados
//-------------------------------------------------------------------
Static Function ModelDef()

	// Cria a estrutura a ser usada no Modelo de Dados
	Local oStruSA1  := FWFormStruct( 1, 'SA1', {|cCampo| Alltrim(cCampo) $ "A1_COD,A1_LOJA,A1_NOME,A1_CGC" },/*lViewUsado*/ )
	Local oStruUC4  := FWFormStruct( 1, 'UC4', /*bAvalCampo*/,/*lViewUsado*/ )
	Local oModel

	// Cria o objeto do Modelo de Dados
	oModel := MPFormModel():New('TRETM052', /*bPreValidacao*/, /*bPosValidacao*/, /*bCommit*/, /*bCancel*/ )

	// Adiciona ao modelo uma estrutura de formulario de edicao por campo
	oModel:AddFields( 'SA1MASTER', /*cOwner*/, oStruSA1, /*bPreValidacao*/, /*bPosValidacao*/, /*bCarga*/ )

	// Adiciona a chave primaria da tabela principal
	oModel:SetPrimaryKey({ "A1_FILIAL", "A1_COD", "A1_LOJA" })

	// Adiciona ao modelo uma componente de grid
	oModel:AddGrid( 'UC4DETAIL', 'SA1MASTER', oStruUC4 , /*bLinePre*/, /*bLinePost*/, /*bPreVal*/, /*bPosVal*/, /*BLoad*/ )

	// Faz relacionamento entre os componentes do model
	oModel:SetRelation( 'UC4DETAIL', { {'UC4_FILIAL', 'xFilial( "UC4" )'}, {'UC4_CLIENT', 'A1_COD'}, {'UC4_LOJA', 'A1_LOJA'} }, UC4->( IndexKey( 1 ) ) )

	// Liga o controle de nao repeticao de linha
	oModel:GetModel( 'UC4DETAIL' ):SetUniqueLine( { 'UC4_SEG' } )

	// Adiciona a descricao do Modelo de Dados
	oModel:SetDescription( 'Limites Cliente por Segmento' )

	// Adiciona a descrição dos Componentes do Modelo de Dados
	oModel:GetModel( 'UC4DETAIL' ):SetDescription( 'Limites Cliente por Segmento' )

	// tira obrigatoriedade de incluir linha
	oModel:GetModel( 'UC4DETAIL' ):SetOptional(.T.)

Return oModel

//-------------------------------------------------------------------
// Define camada de Visão
//-------------------------------------------------------------------
Static Function ViewDef()

	// Cria um objeto de Modelo de Dados baseado no ModelDef do fonte informado
	Local oModel   := FWLoadModel( 'TRETA052' )
	Local oView

	// Cria a estrutura a ser usada na View
	Local oStruSA1 := FWFormStruct( 2, 'SA1', {|cCampo| Alltrim(cCampo) $ "A1_COD,A1_LOJA,A1_NOME,A1_CGC" },/*lViewUsado*/ )
	Local oStruUC4 := FWFormStruct( 2, 'UC4', /*bAvalCampo*/,/*lViewUsado*/ )

	//removo as pastas
	oStruSA1:aFolders := {}

	// Remove campos da estrutura
	oStruUC4:RemoveField( 'UC4_CLIENT' )
	oStruUC4:RemoveField( 'UC4_LOJA' )
	oStruUC4:RemoveField( 'UC4_GRUPO' )

	// Cria o objeto de View
	oView := FWFormView():New()

	// Define qual o Modelo de dados ser· utilizado
	oView:SetModel( oModel )

	//Adiciona no nosso View um controle do tipo FormFields(antiga enchoice)
	oView:AddField( 'VIEW_SA1', oStruSA1, 'SA1MASTER' )

	//Adiciona no nosso View um controle do tipo Grid (antiga Getdados)
	oView:AddGrid( 'VIEW_UC4', oStruUC4, 'UC4DETAIL' )

	// Cria um "box" horizontal para receber cada elemento da view
	oView:CreateHorizontalBox( 'SUPERIOR'	, 20 )
	oView:CreateHorizontalBox( 'INFERIOR'	, 80 )

	// Relaciona o identificador (ID) da View com o "box" para exibição
	oView:SetOwnerView( 'VIEW_SA1', 'SUPERIOR' )
	oView:SetOwnerView( 'VIEW_UC4', 'INFERIOR' )

	// titulo dos componentes
	oView:EnableTitleView('VIEW_UC4' , /*'item'*/)

	//coloca cabeçalho apenas para visualizar.
	oView:SetOnlyView("SA1MASTER")

Return oView

User Function TRET052A()
    
    Local nOpc 
	Local lEditaLC := .T.
	Local lMvPosto := SuperGetMv("MV_XPOSTO",.F.,.F.) //Habilita Posto de Combustível (Posto Inteligente).

	if lMvPosto
		//cadastra rotina para controle de acesso
		U_TRETA37B("INALLC", "INCLUI/ALTERA LIMITE DE CREDITO POR SEGMENTO")
		//verifica se o usuário tem permissão para acesso a rotina
		lEditaLC := U_VLACESS2("INALLC", RetCodUsr())
	endif

	//Atualizo saldo limite de credito do cliente/grupo antes de abrir tela
	LjMsgRun("Aguarde... Atualizando saldos de limite de credito...",,{|| U_TRET052B() })

    ACY->(DbSetOrder(1))

    if !empty(SA1->A1_GRPVEN) .AND. ACY->(DbSeek(xFilial("ACY")+SA1->A1_GRPVEN))

        nOpc := Aviso("Limite por Segmento", "O Cliente selecionado está amarrado a um Grupo de Clientes.", {"Cliente","Grupo"}, 3, "Ajustar limite por?")

        if nOpc == 1
			if lEditaLC
            	FWExecView('Alterar','TRETA052', 4,, {|| .T. })
			else
				FWExecView('Visualizar','TRETA052', 1,, {|| .T. })
			endif
        else
			if lEditaLC
            	FWExecView('Alterar','TRETA053', 4,, {|| .T. })
			else
				FWExecView('Visualizar','TRETA053', 1,, {|| .T. })
			endif
        endif

    else //apenas cliente
        if lEditaLC
			FWExecView('Alterar','TRETA052', 4,, {|| .T. })
		else
			FWExecView('Visualizar','TRETA052', 1,, {|| .T. })
		endif
    endif

Return

//Atualiza saldo do cliente/grupo antes de abrir a tela
User Function TRET052B()
	
	Local nSaldoLC := 0
	Local nSaldoLCSaq := 0

	//atualizando saldo venda por cliente
	UC4->(DbSetOrder(1)) //UC4_FILIAL+UC4_CLIENT+UC4_LOJA+UC4_SEG
	if UC4->(DbSeek(xFilial("UC4")+SA1->A1_COD+SA1->A1_LOJA ))
		While UC4->(!Eof()) .AND. UC4->UC4_FILIAL+UC4->UC4_CLIENT+UC4->UC4_LOJA == xFilial("UC4")+SA1->A1_COD+SA1->A1_LOJA

			//Comentei o UC4_LIMVEN pois o campo Saldo agora será referente ao saldo usado do limite, e nao o saldo disponível
			nSaldoLC := /*(UC4->UC4_LIMVEN) - */(U_TRETE032(1,{{SA1->A1_COD,SA1->A1_LOJA,''}}, UC4->UC4_SEG )[01][01])
			nSaldoLCSaq := /*(UC4->UC4_LIMVEN) - */(U_TRETE032(2,{{SA1->A1_COD,SA1->A1_LOJA,''}}, UC4->UC4_SEG )[01][01])
			RecLock("UC4", .F.)
				UC4->UC4_SALDO := nSaldoLC
				UC4->UC4_SALSAQ := nSaldoLCSaq
			UC4->(MsUnlock())

			UC4->(DbSkip())
		enddo
	endif

	//atualizando saldo por grupo
	if !empty(SA1->A1_GRPVEN)
		UC4->(DbSetOrder(2)) //UC4_FILIAL+UC4_GRUPO+UC4_SEG
		if UC4->(DbSeek(xFilial("UC4")+SA1->A1_GRPVEN ))
			While UC4->(!Eof()) .AND. UC4->UC4_FILIAL+UC4->UC4_GRUPO == xFilial("UC4")+SA1->A1_GRPVEN

				//Comentei o UC4_LIMVEN pois o campo Saldo agora será referente ao saldo usado do limite, e nao o saldo disponível
				nSaldoLC := /*(UC4->UC4_LIMVEN) - */(U_TRETE032(1,{{'','',UC4->UC4_GRUPO}}, UC4->UC4_SEG )[01][02])
				nSaldoLCSaq := /*(UC4->UC4_LIMVEN) - */(U_TRETE032(2,{{'','',UC4->UC4_GRUPO}}, UC4->UC4_SEG )[01][02])
				RecLock("UC4", .F.)
					UC4->UC4_SALDO := nSaldoLC
					UC4->UC4_SALSAQ := nSaldoLCSaq
				UC4->(MsUnlock())

				UC4->(DbSkip())
			enddo
		endif
	endif

Return
