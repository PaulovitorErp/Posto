

#INCLUDE 'FWMVCDEF.CH'
#include 'poscss.ch'

#include "topconn.ch"
#include "TOTVS.CH"

/*/{Protheus.doc} TRETA037
Cadastro Controle de Acesso / Alçada
@author thebr
@since 20/05/2019
@version 1.0
@return Nil
@type function
/*/
user function TRETA037()

	Local oBrowse

	DbSelectArea('U03')
	DbSelectArea('U04')
	DbSelectArea('UC2')
	DbSelectArea('U0D')

	U_TRETA37C()

	oBrowse := FWmBrowse():New()
	oBrowse:SetAlias( 'U03' )
	oBrowse:SetDescription( 'Cadastro Perfil de Acesso/Alçada' )
	oBrowse:Activate()

return

/*/{Protheus.doc} MenuDef
Definilção do Menu
@author thebr
@since 20/05/2019
@version 1.0
@return aRotina
@type function
/*/
Static Function MenuDef()

	Local aRotina := {}

	ADD OPTION aRotina TITLE 'Visualizar'      ACTION 'VIEWDEF.TRETA037' OPERATION 2 ACCESS 0
	ADD OPTION aRotina TITLE 'Incluir'         ACTION 'VIEWDEF.TRETA037' OPERATION 3 ACCESS 0
	ADD OPTION aRotina TITLE 'Alterar'         ACTION 'VIEWDEF.TRETA037' OPERATION 4 ACCESS 0
	ADD OPTION aRotina TITLE 'Excluir'         ACTION 'VIEWDEF.TRETA037' OPERATION 5 ACCESS 0
	ADD OPTION aRotina TITLE 'Copiar'          ACTION 'VIEWDEF.TRETA037' OPERATION 9 ACCESS 0

Return aRotina

/*/{Protheus.doc} ModelDef
Definição do Modelo
@author thebr
@since 20/05/2019
@version 1.0
@return Nil
@type function
/*/
Static Function ModelDef()

	// Cria a estrutura a ser usada no Modelo de Dados
	Local oStruU03  := FWFormStruct( 1, 'U03', /*bAvalCampo*/,/*lViewUsado*/ )
	Local oStruU04  := FWFormStruct( 1, 'U04', /*bAvalCampo*/,/*lViewUsado*/ )
	Local oStruUC2  := FWFormStruct( 1, 'UC2', /*bAvalCampo*/,/*lViewUsado*/ )
	Local oStruU0D  := FWFormStruct( 1, 'U0D', /*bAvalCampo*/,/*lViewUsado*/ )
	Local oModel
	Local cUserAdm  := SuperGetMv("MV_XUSRADM",,"") //Usuários Administradores
	Local cUsuario := RetCodUsr()

	// Cria o objeto do Modelo de Dados
	oModel := MPFormModel():New('TRETM037', /*bPreValidacao*/, /*bPosValidacao*/, /*bCommit*/, /*bCancel*/ )

	// Adiciona ao modelo uma estrutura de formul·rio de ediÁ?o por campo
	oModel:AddFields( 'U03MASTER', /*cOwner*/, oStruU03, /*bPreValidacao*/, /*bPosValidacao*/, /*bCarga*/ )

	// Adiciona a chave primaria da tabela principal
	oModel:SetPrimaryKey({ "U03_FILIAL" , "U03_GRUPO", "U03_USER" })

	If cUsuario == "000000" .OR. cUsuario $ cUserAdm//se administrador

		// Adiciona ao modelo uma componente de grid Credito
		oModel:AddGrid( 'UC2DETAIL', 'U03MASTER', oStruUC2 , /*bLinePre*/, /*bLinePost*/, /*bPreVal*/, /*bPosVal*/, /*BLoad*/ )

		// Faz relacionamento entre os componentes do model
		oModel:SetRelation( 'UC2DETAIL', { {'UC2_FILIAL', 'xFilial("UC2")'}, {'UC2_GRUPO', 'U03_GRUPO'}, {"UC2_USER", "U03_USER"} }, UC2->( IndexKey( 1 ) ) )

		// Liga o controle de nao repeticao de linha
		oModel:GetModel( 'UC2DETAIL' ):SetUniqueLine( { 'UC2_ROTINA' } )
		oModel:GetModel( 'UC2DETAIL' ):SetDescription( 'Rotinas/Ações Customizadas' )

	EndIf

	// Adiciona ao modelo uma componente de grid Credito
	oModel:AddGrid( 'U04DETAIL', 'U03MASTER', oStruU04 , /*bLinePre*/, /*bLinePost*/, /*bPreVal*/, /*bPosVal*/, /*BLoad*/ )

	// Faz relacionamento entre os componentes do model
	oModel:SetRelation( 'U04DETAIL', { {'U04_FILIAL', 'xFilial("U04")'}, {'U04_GRUPO', 'U03_GRUPO'}, {"U04_USER", "U03_USER"} }, U04->( IndexKey( 1 ) ) )

	// Liga o controle de nao repeticao de linha
	oModel:GetModel( 'U04DETAIL' ):SetUniqueLine({'U04_GRPCLI',"U04_CLIENT","U04_LOJCLI","U04_FORMPG","U04_CONDPG","U04_GRPPRO","U04_PRODUT"})
	oModel:GetModel( 'U04DETAIL' ):SetOptional(.T.)

	// Adiciona ao modelo uma estrutura de formulario de ediavel por campo
	oModel:AddFields( 'U0DDETAIL', 'U03MASTER', oStruU0D, /*bPreValidacao*/, /*bPosValidacao*/, /*bCarga*/ )

	// Faz relacionamento entre os componentes do model
	oModel:SetRelation( 'U0DDETAIL', { {'U0D_FILIAL', 'xFilial("U0D")'}, {'U0D_GRUPO', 'U03_GRUPO'}, {"U0D_USER", "U03_USER"} }, U0D->( IndexKey( 1 ) ) )

	// Adiciona a descricao do Modelo de Dados
	oModel:SetDescription( 'Modelo de Perfil de Acesso' )

	// Adiciona a descrição dos Componentes do Modelo de Dados
	oModel:GetModel( 'U03MASTER' ):SetDescription( 'Perfil de Acesso' )
	oModel:GetModel( 'U04DETAIL' ):SetDescription( 'Descontos Venda PDV' )
	oModel:GetModel( 'U0DDETAIL' ):SetDescription( 'Outras Definições' )

	// Bloco validacao para abertura do modelo
	oModel:SetVldActivate( {|oModel| iif(oModel:GetOperation()==4, U_TRETA37D(2), .T.) } )

Return oModel

/*/{Protheus.doc} ViewDef
Definição da visão
@author thebr
@since 20/05/2019
@version 1.0
@return Nil
@type function
/*/
Static Function ViewDef()

	// Cria um objeto de Modelo de Dados baseado no ModelDef do fonte informado
	Local oModel   := FWLoadModel( 'TRETA037' )
	Local oView
	Local cUserAdm  := SuperGetMv("MV_XUSRADM",,"") //Usuários Administradores
	Local cUsuario := RetCodUsr()

	// Cria a estrutura a ser usada na View
	Local oStruU03 := FWFormStruct( 2, 'U03' )
	Local oStruUC2 := FWFormStruct( 2, 'UC2' )
	Local oStruU04 := FWFormStruct( 2, 'U04' )
	Local oStruU0D := FWFormStruct( 2, 'U0D' )

	// Remove campos da estrutura
	If cUsuario == "000000" .OR. cUsuario $ cUserAdm//se administrador
		oStruUC2:RemoveField( 'UC2_GRUPO' )
		oStruUC2:RemoveField( 'UC2_USER' )
		oStruUC2:RemoveField( 'UC2_NOMEU') //legado
	EndIf
	oStruU04:RemoveField( 'U04_GRUPO' )
	oStruU04:RemoveField( 'U04_USER' )
	oStruU0D:RemoveField( 'U0D_GRUPO' )
	oStruU0D:RemoveField( 'U0D_USER' )

	// Cria o objeto de View
	oView := FWFormView():New()

	// Define qual o Modelo de dados ser· utilizado
	oView:SetModel( oModel )

	//Adiciona no nosso View um controle do tipo FormFields(antiga enchoice)
	oView:AddField( 'VIEW_U03', oStruU03, 'U03MASTER' )

	If cUsuario == "000000" .OR. cUsuario $ cUserAdm//se administrador
		//Adiciona no nosso View um controle do tipo Grid (antiga Getdados)
		oView:AddGrid( 'VIEW_UC2', oStruUC2, 'UC2DETAIL' )
		oView:SetNoInsertLine('VIEW_UC2') //bloqueio nao inserir
		oView:SetNoDeleteLine('VIEW_UC2') //bloqueio nao inserir
	EndIf

	oView:AddGrid( 'VIEW_U04', oStruU04, 'U04DETAIL' )
	// Define campos que terao Auto Incremento
	oView:AddIncrementField( 'VIEW_U04', 'U04_ITEM' )

	oView:AddField( 'VIEW_U0D', oStruU0D, 'U0DDETAIL' )

	// Cria um "box" horizontal para receber cada elemento da view
	oView:CreateHorizontalBox( 'SUPERIOR'	, 25 )
	oView:CreateHorizontalBox( 'INFERIOR'	, 75 )

	// Cria Folder na view
	oView:CreateFolder( 'PASTAS', 'INFERIOR')

	// Cria pastas na parte inferior da tela - Itens
	If cUsuario == "000000" .OR. cUsuario $ cUserAdm//se administrador
		oView:AddSheet('PASTAS', 'ABA01', 'Acesso Rotinas/Ações')
		oView:CreateHorizontalBox( 'MEIO1_PNL', 100,,,'PASTAS', 'ABA01')
		oView:SetOwnerView( 'VIEW_UC2' , 'MEIO1_PNL' )
		//oView:EnableTitleView('VIEW_UC2' , /*'item'*/)
	EndIf

	oView:AddSheet('PASTAS', 'ABA02', 'Alçadas')
	oView:CreateHorizontalBox( 'ABA02_SUP', 50 ,,,'PASTAS', 'ABA02')
	oView:CreateHorizontalBox( 'ABA02_INF', 50 ,,,'PASTAS', 'ABA02')

	// Relaciona o identificador (ID) da View com o "box" para exibição
	oView:SetOwnerView( 'VIEW_U03' , 'SUPERIOR' )
	oView:SetOwnerView( 'VIEW_U04' , 'ABA02_SUP' )
	oView:SetOwnerView( 'VIEW_U0D' , 'ABA02_INF' )

	// titulo dos componentes
	//oView:EnableTitleView('VIEW_U03' ,/*'cabecalho'*/)
	oView:EnableTitleView('VIEW_U04' , /*'item'*/)
	oView:EnableTitleView('VIEW_U0D' , /*'item'*/)

Return oView

//-------------------------------------------------------------------
/*/{Protheus.doc} TRETA37A
Função que cadastra tabela generica U5
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
User Function TRETA37A()

	Local lRet := .T.
	Local aContent := {} //campos de uma tabela no SX5 (Vetor com os dados do SX5 - com: [1] FILIAL [2] TABELA [3] CHAVE [4] DESCRICAO)
	Local cDescri := ""
	Local aArea := GetArea()
	Local aAreaSX5 := SX5->(GetArea())

	//X5_FILIAL+X5_TABELA+X5_CHAVE

	aContent := FWGetSX5( "00", PadR("U5", TamSx3("X5_CHAVE")[1]) )
	If Len(aContent) = 0 .or. Empty(aContent[1][4]) //se nao tem a tabela criada ainda.. cria.
		//cDescri := PadR("ROTINAS CUST. CONTROLE ACESSO",TamSx3("X5_DESCRI")[1])
		//FwPutSX5(/*cFlavour*/, "00", PadR("U5", TamSx3("X5_CHAVE")[1]), cDescri, cDescri, cDescri, /*cTextoAlt*/)

		//TODO: a função 'FwPutSX5' não esta funcionando....
		DbSelectArea("SX5")
		SX5->(DbSetOrder(1)) //X5_FILIAL+X5_TABELA+X5_CHAVE
		If !SX5->(DbSeek(xFilial("SX5")+"00"+"U5")) //se nao tem a tabela criada ainda.. cria.
			cDescri := PadR("ROTINAS CUST. CONTROLE ACESSO",TamSx3("X5_DESCRI")[1])
			If RecLock("SX5",.T.) //inclui
				SX5->X5_FILIAL  := xFilial("SX5")
				SX5->X5_TABELA  := "00"
				SX5->X5_CHAVE   := "U5"
				SX5->X5_DESCRI  := cDescri
				SX5->X5_DESCSPA := cDescri
				SX5->X5_DESCENG := cDescri		
				SX5->(MsUnlock())
			EndIf
		EndIf

	ElseIf AllTrim(aContent[1][4]) <> "ROTINAS CUST. CONTROLE ACESSO"
		Alert("Não foi possível criar tabela genérica U5, pois ja está em uso. Entre em contato com o Administrador do sistema.", "Controle de Acesso")
		lRet := .F.
	EndIf

	RestArea(aAreaSX5)
	RestArea(aArea)

Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} TRETA37B
Função que cadastra rotinas para acesso na tabela generica U5
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
User Function TRETA37B(cRotina, cDescri)

	Local aContent := {} //campos de uma tabela no SX5 (Vetor com os dados do SX5 - com: [1] FILIAL [2] TABELA [3] CHAVE [4] DESCRICAO)

	If !U_TRETA37A()
		Return
	EndIf

	aContent := FWGetSX5( "U5", PadR(cRotina, TamSx3("X5_CHAVE")[1]) )
	If Len(aContent) = 0 .or. AllTrim(aContent[1][4]) <> AllTrim(cDescri)
		//cDescri := PadR(cDescri,TamSx3("X5_DESCRI")[1])
		//FwPutSX5(/*cFlavour*/, "U5", PadR(cRotina, TamSx3("X5_CHAVE")[1]), cDescri, cDescri, cDescri, /*cTextoAlt*/)
		
		//TODO: a função 'FwPutSX5' não esta funcionando....
		DbSelectArea("SX5")
		SX5->(DbSetOrder(1)) //X5_FILIAL+X5_TABELA+X5_CHAVE
		If !SX5->(DbSeek(xFilial("SX5")+"U5"+PadR(cRotina, TamSx3("X5_CHAVE")[1]))) //se nao tem a tabela criada ainda.. cria.
			cDescri := PadR(cDescri,TamSx3("X5_DESCRI")[1])
			If RecLock("SX5",.T.) //inclui
				SX5->X5_FILIAL  := xFilial("SX5")
				SX5->X5_TABELA  := "U5"
				SX5->X5_CHAVE   := PadR(cRotina, TamSx3("X5_CHAVE")[1])
				SX5->X5_DESCRI  := cDescri
				SX5->X5_DESCSPA := cDescri
				SX5->X5_DESCENG := cDescri		
				SX5->(MsUnlock())
			EndIf
		EndIf

	EndIf

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} TRETA37C
Função que define e cria as rotinas para cofiguração dos acessos
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
User Function TRETA37C()

	Local lAcessTF := SuperGetMv("TP_ACESSTF",,.F.) //Define se valida acesso na opção troca forma

	//PDV
	U_TRETA37B("AFEPDV", "AFERICAO PDV")
	U_TRETA37B("AFEMAX", "AFERICAO ACIMA DO MAXIMO PERMITIDO (TP_AFMAXLT)")
	U_TRETA37B("CMPPDV", "COMPENSACAO DE VALORES PDV")
	U_TRETA37B("DEPPDV", "DEPOSITO NO PDV")
	U_TRETA37B("DESPDV", "DESCONTO NO PDV")
	U_TRETA37B("EXCORC", "EXCLUSAO DE ORCAMENTO PDV")
	U_TRETA37B("MATBOM", "MANUTENCAO DE BOMBA NO PDV")
	U_TRETA37B("SAQPDV", "SAQUE NO PDV")
	U_TRETA37B("VLSPDV", "VALE SERVICO PDV")
	U_TRETA37B("LIBVSL", "LIBERAR VENDA CLIENTE/GRUPO SEM SALDO LIMITE DE CREDITO")
	U_TRETA37B("LIBVBL", "LIBERAR VENDA CLIENTE/GRUPO COM BLOQUEIO CREDITO")
	U_TRETA37B("LIBSSL", "LIBERAR SAQUE CLIENTE/GRUPO SEM SALDO LIMITE DE CREDITO")
	U_TRETA37B("LIBSBL", "LIBERAR SAQUE CLIENTE/GRUPO COM BLOQUEIO CREDITO")
	U_TRETA37B("BXTROC", "BAIXA TROCADA NO PDV")
	U_TRETA37B("VLDCAN", "CANCELAMENTO DE CUPOM NO PDV (TP_VLCCANC)")
	U_TRETA37B("PRCBIC", "ENVIA PREÇO PARA BICO ")

	//RETAGUARDA
	U_TRETA37B("ALT062", "ALTERAR TITULO - ROTINA IMPORTAR EXTRATO OPERADORAS")
	U_TRETA37B("CHQTRC", "TRANSFERENCIA DE CHEQUE TROCO")
	U_TRETA37B("CONFCX", "PERMITE CONFERIR O CAIXA")
	U_TRETA37B("ESTOCX", "PERMITE ESTORNAR O CAIXA")
	U_TRETA37B("FCXCAN", "FECHAMENTO DE CAIXA: CANCELAR VENDA")
	U_TRETA37B("U25DEL", "EXCLUSAO DE PRECO NEGOCIADO")
	U_TRETA37B("U44UPD", "INCLUI/ALTERA NEGOCIACAO DE PAGAMENTO")
	U_TRETA37B("UFT001", "INCLUIR NEGOCIACAO DE PRECOS")
	U_TRETA37B("UFT002", "ATUALIZAR PRECOS NEGOCIADOS")
	U_TRETA37B("UFT010", "AMARRACAO DE PLACA")
	U_TRETA37B("FT006A", "BOTAO DIVERSOS NA ROTINA GERA NF-E CUPOM")
	If lAcessTF
		U_TRETA37B("TFORMA", "TROCAR FORMA - CONFERENCIA CAIXA")
	EndIf
	U_TRETA37B("MIEDLM", "ULTRAPASSAR LIMITE DE ESTOQUE DE FECHAMENTO: MV_XPERCGP")

	//PORTAL POSTO - WEB
	U_TRETA37B("PPIMAB", "PORTAL POSTO - MONITOR ABASTECIMENTO")
	U_TRETA37B("PPIMCG", "PORTAL POSTO - MONITOR CARGAS")
	U_TRETA37B("PPICLC", "PORTAL POSTO - CONSULTAS LIMITE CREDITO")
	U_TRETA37B("PPICPR", "PORTAL POSTO - CONSULTAS PRECOS")

Return

/*/{Protheus.doc} TRETA37D
Adiciona rotinas no grid do cadastro de permissao de acesso

@author thebr
@since 21/05/2019
@version 1.0
@return Nil
@param nTipo, numeric, 1=Add no Model do MVC; 2=Add via Lock na tabela
@type function
/*/
User Function TRETA37D(nTipo)

	Local aRotAcesso := {}
	Local oView, oModel, oMdlUC2
	Local nX
	Local cUserAdm  := SuperGetMv("MV_XUSRADM",,"") //Usuários Administradores
	Local cUsuario := RetCodUsr()
	Local aContent := {} //campos de uma tabela no SX5 (Vetor com os dados do SX5 - com: [1] FILIAL [2] TABELA [3] CHAVE [4] DESCRICAO)

	If !(cUsuario == "000000" .OR. cUsuario $ cUserAdm) //se não administrador
		Return .T.
	EndIf

	aContent := FWGetSX5( "U5" )
	If Len(aContent) > 0
		For nX := 1 to Len(aContent)
			aadd(aRotAcesso, {aContent[nX][3], aContent[nX][4]})
		Next nX
	EndIf

	If !Empty(aRotAcesso)

		If nTipo == 1
			oView	:= FWViewActive()
			oModel  := FWModelActive()
			oMdlUC2 := oModel:GetModel( 'UC2DETAIL' )
			oMdlUC2:SetNoInsertLine(.F.)

			oMdlUC2:SetLine(1)
			If Empty(oMdlUC2:GetValue( 'UC2_ROTINA')) //somente se esta vazio

				//insiro a primeira linha
				oMdlUC2:LoadValue("UC2_ROTINA", aRotAcesso[1][1])
				oMdlUC2:LoadValue("UC2_DESROT", aRotAcesso[1][2])
				oMdlUC2:LoadValue("UC2_ACESSO", .F.)

				//insoro demais linhas
				for nX := 2 to len(aRotAcesso)
					oMdlUC2:AddLine()
					oMdlUC2:GoLine(oMdlUC2:Length())

					oMdlUC2:LoadValue("UC2_ROTINA",aRotAcesso[nX][1])
					oMdlUC2:LoadValue("UC2_DESROT",aRotAcesso[nX][2])
					oMdlUC2:LoadValue("UC2_ACESSO", .F.)
				next nX

			EndIf

			oMdlUC2:SetNoInsertLine(.T.)
			oMdlUC2:GoLine(1)
			If oView <> Nil
				oView:Refresh()
			EndIf

		Else //via reclock

			UC2->(DbSetOrder(1))

			for nX := 2 to len(aRotAcesso)
				If !UC2->(DbSeek(xFilial("UC2")+U03->U03_GRUPO+U03->U03_USER+aRotAcesso[nX][1]))
					Reclock("UC2", .T.)
					UC2->UC2_FILIAL := xFilial("UC2")
					UC2->UC2_GRUPO := U03->U03_GRUPO
					UC2->UC2_USER := U03->U03_USER
					UC2->UC2_ROTINA := aRotAcesso[nX][1]
					UC2->UC2_DESROT := aRotAcesso[nX][2]
					UC2->UC2_ACESSO := .F.
					UC2->(MsUnlock())
				EndIf
			next nX

		EndIf
	EndIf

Return .T.

//-------------------------------------------------------------------
/*/{Protheus.doc} VLACESS1
Função que valida se o usuário tem acesso a rotina. Caso nao tenha, solicita
usuário e senha de alguem que tenha acesso a rotina para liberar uso.
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
User Function VLACESS1(cRotina, cUsuario)

	Local _cRet_ := ""
	Local aLogin := {}
	Local aGrpUsr := {}
	Local nX, cMsgErr
	Local cDescri := "acessar esta rotina"
	Local cUserAdm  := SuperGetMv("MV_XUSRADM",,"") //Usuários Administradores
	Local aContent := {} //campos de uma tabela no SX5 (Vetor com os dados do SX5 - com: [1] FILIAL [2] TABELA [3] CHAVE [4] DESCRICAO)

	If cUsuario == "000000" .OR. cUsuario $ cUserAdm//se administrador
		return cUsuario
	EndIf

	DbSelectArea("UC2")
	UC2->(DbSetOrder(2)) //UC2_FILIAL+UC2_ROTINA+UC2_USER+UC2_GRUPO
	//LIBERANDO POR USUARIO
	If UC2->(DbSeek(xFilial("UC2")+cRotina+cUsuario+space(TamSX3("UC2_GRUPO")[1])))
		If UC2->UC2_ACESSO
			_cRet_ := UC2->UC2_USER //autorizado
		EndIf
	Else
		//LIBERANDO POR GRUPO
		aGrpUsr := UsrRetGrp(UsrRetName(cUsuario), cUsuario)
		If Len(aGrpUsr)>0
			DbSelectArea("UC2")
			UC2->(DbSetOrder(2)) //UC2_FILIAL+UC2_ROTINA+UC2_USER+UC2_GRUPO
			For nX := 1 to len(aGrpUsr)
				If UC2->(DbSeek(xFilial("UC2")+cRotina+space(TamSX3("UC2_USER")[1])+aGrpUsr[nX]))
					If UC2->UC2_ACESSO
						_cRet_ := cUsuario //autorizado
						EXIT //sai do laço
					EndIf
				EndIf
			next nX
		EndIf
	EndIf

	//SE NAO LIBERADO CHAMA TELA
	If Empty(_cRet_)
		aContent := FWGetSX5( "U5", PadR(cRotina, TamSx3("X5_CHAVE")[1]) )
		If Len(aContent) > 0 .and. !Empty(aContent[1][4])
			cDescri := aContent[1][4] //[4] DESCRICAO --> X5_DESCRI
		EndIf
		cMsgErr := "Usuário sem permissão para "+Alltrim(cDescri)+". Solicite autorização de um supervisor!"
		aLogin := U_TelaLogin(cMsgErr)
		If !Empty(aLogin)
			_cRet_ := U_VLACESS1(cRotina, aLogin[1])
		EndIf
	EndIf

Return _cRet_

//-------------------------------------------------------------------
/*/{Protheus.doc} VLACESS2
Função que apenas valida se o usuário tem acesso a rotina.
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
User Function VLACESS2(cRotina, cUsuario, lMsg)

	Local _lRet_ := .F.
	Local aGrpUsr := {}
	Local nX
	Local cDescri := "acessar esta rotina"
	Local cUserAdm  := SuperGetMv("MV_XUSRADM",,"") //Usuários Administradores
	Local aContent := {} //campos de uma tabela no SX5 (Vetor com os dados do SX5 - com: [1] FILIAL [2] TABELA [3] CHAVE [4] DESCRICAO)

	Default lMsg := .F.

	If cUsuario == "000000" .OR. cUsuario $ cUserAdm//se administrador
		return .T.
	EndIf

	DbSelectArea("UC2")
	UC2->(DbSetOrder(2)) //UC2_FILIAL+UC2_ROTINA+UC2_USER+UC2_GRUPO
	//LIBERANDO POR USUARIO
	If UC2->(DbSeek(xFilial("UC2")+cRotina+cUsuario+space(TamSX3("UC2_GRUPO")[1])))
		_lRet_ := UC2->UC2_ACESSO
	Else
		//LIBERANDO POR GRUPO
		aGrpUsr := UsrRetGrp(UsrRetName(cUsuario), cUsuario)
		If Len(aGrpUsr)>0
			DbSelectArea("UC2")
			UC2->(DbSetOrder(2)) //UC2_FILIAL+UC2_ROTINA+UC2_USER+UC2_GRUPO
			For nX := 1 to len(aGrpUsr)
				If UC2->(DbSeek(xFilial("UC2")+cRotina+space(TamSX3("UC2_USER")[1])+aGrpUsr[nX]))
					_lRet_ := UC2->UC2_ACESSO //autorizado
					EXIT //sai do laço
				EndIf
			next nX
		EndIf

		If !_lRet_ .AND. lMsg
			aContent := FWGetSX5( "U5", PadR(cRotina, TamSx3("X5_CHAVE")[1]) )
			If Len(aContent) > 0 .and. !Empty(aContent[1][4])
				cDescri := aContent[1][4] //[4] DESCRICAO --> X5_DESCRI
			EndIf
			Alert("Usuário sem permissão para "+Alltrim(cDescri)+".")
		EndIf
	EndIf

Return _lRet_

/*/{Protheus.doc} TelaLogin

Abre tela login para liberacao de acesso a rotina
@author thebr
@since 21/05/2019
@version 1.0
@return Nil
@type function
/*/
User Function TelaLogin(cMsgErr, cTitle, lHlpMemo, lCodAcess)

	Local oButton1
	Local oButton2
	Local oSay1
	Local cGetUser 		:= Space(25)
	Local cGetSenha		:= Space(25)
	Local cGetCLib		:= iif(SL4->(FieldPos("L4_XCODLIB")) > 0, Space(TamSX3("L4_XCODLIB")[1]), "")
	Local cCodUser		:= ""
	Local aRet			:= {}
	Local oLogo, nWidth, nHeight
	Local bCloseDlg := {|x| aRet:={}, oDlgUsr:End() }
	Local lAlcClb := SuperGetMv("MV_XALCCLB",,.F.) //Habilita liberação de alçadas por código de liberação (default .F.)

	Default cMsgErr := ""
	Default cTitle := "Validação de Acesso"
	Default lHlpMemo := .F.

	Private oSayUser, oGetUser, oSaySenha, oGetSenha, oSayCLib, oGetCLib, oButCLib, oButUser
	Private oHelpLg, cHelpLg, oPnlFull
	Private oDlgUsr
	Private nTpLib := 1

	Default lCodAcess := .F.

	cHelpLg := cMsgErr
	lCodAcess := lCodAcess .and. lAlcClb .and. SL4->(FieldPos("L4_XCODLIB")) > 0

	If lHlpMemo
		DEFINE MSDIALOG oDlgUsr TITLE "" FROM 000,000 TO 470,375 PIXEL STYLE nOr(WS_VISIBLE, WS_POPUP)
	Else
		DEFINE MSDIALOG oDlgUsr TITLE "" FROM 000,000 TO 400,375 PIXEL STYLE nOr(WS_VISIBLE, WS_POPUP)
	EndIf

	nWidth := (oDlgUsr:nWidth/2)
	nHeight := (oDlgUsr:nHeight/2)

	@ 000, 000 MSPANEL oPnlFull SIZE nWidth, nHeight OF oDlgUsr
	oPnlFull:SetCSS( "TPanel{border: 2px solid #999999; background-color: #f4f4f4;}" )

	@ 000, 000 MSPANEL oPnlTop SIZE nWidth, 017 OF oPnlFull
	oPnlTop:SetCSS( POSCSS (GetClassName(oPnlTop), CSS_BAR_TOP ))
	@ 004, 005 SAY oSay1 PROMPT cTitle SIZE 100, 015 OF oPnlTop COLORS 0, 16777215 PIXEL
	oSay1:SetCSS( POSCSS (GetClassName(oSay1), CSS_BREADCUMB ))
	oClose := TBtnBmp2():New( 002,oDlgUsr:nWidth-25,20,30,'FWSKIN_DELETE_ICO',,,,bCloseDlg,oPnlTop,,,.T. )
	oClose:SetCss("TBtnBmp2{border: none;background-color: none;}")

	@ 030, 050 REPOSITORY oLogo SIZE 100, 100 OF oPnlFull PIXEL NOBORDER
	oLogo:LoadBmp("FWSKIN_LOGO_TOTVS.PNG")

	@ 075, 010 SAY oSayUser PROMPT "Usuário:" SIZE 040, 008 OF oPnlFull PIXEL
	oSayUser:SetCSS( POSCSS (GetClassName(oSayUser), CSS_LABEL_FOCAL ))
	@ 085, 010 MSGET oGetUser VAR cGetUser SIZE nWidth-20, 013 OF oPnlFull COLORS 0, 16777215 PIXEL
	oGetUser:SetCSS( POSCSS (GetClassName(oGetUser), CSS_GET_NORMAL ))

	@ 105, 010 SAY oSaySenha PROMPT "Senha:" SIZE 040, 008 OF oPnlFull PIXEL
	oSaySenha:SetCSS( POSCSS (GetClassName(oSaySenha), CSS_LABEL_FOCAL ))
	@ 115, 010 MSGET oGetSenha VAR cGetSenha SIZE nWidth-20, 013 Password OF oPnlFull COLORS 0, 16777215 PIXEL
	oGetSenha:SetCSS( POSCSS (GetClassName(oGetSenha), CSS_GET_NORMAL ))

	If lCodAcess
		@ 075, 010 SAY oSayCLib PROMPT "Código Liberação:" SIZE 060, 008 OF oPnlFull PIXEL
		oSayCLib:SetCSS( POSCSS (GetClassName(oSayCLib), CSS_LABEL_FOCAL ))
		@ 085, 010 MSGET oGetCLib VAR cGetCLib PICTURE PesqPict("SL4","L4_XCODLIB") SIZE nWidth-20, 013 OF oPnlFull COLORS 0, 16777215 PIXEL
		oGetCLib:SetCSS( POSCSS (GetClassName(oGetCLib), CSS_GET_NORMAL ))
	EndIf

	If lHlpMemo
		@ 140, 010 GET oHelpLg VAR cHelpLg OF oPnlFull MULTILINE SIZE nWidth-20, 080 COLORS 0, 16777215 PIXEL
		oHelpLg:lReadOnly := .T.
		oHelpLg:lCanGotFocus := .F.
		oHelpLg:SetCSS( POSCSS (GetClassName(oHelpLg), CSS_GET_NORMAL))
	Else
		@ 155, 010 SAY oHelpLg PROMPT cHelpLg PICTURE "@!" SIZE nWidth-15, 040 OF oPnlFull COLORS 0, 16777215 PIXEL
		oHelpLg:SetCSS( "TSay{ font:bold 13px; color: #AA0000; background-color: transparent; border: none; margin: 0px; }" )
	EndIf

	oButton1 := TButton():New( nHeight-20,nWidth-60,"Confirmar",oPnlFull,{|| iif(BtnConfirma(cGetUser,cGetSenha,@cCodUser,cGetCLib,@aRet),oDlgUsr:End(),cCodUser:="")},050,014,,,,.T.,,,,{|| .T.})
	oButton1:SetCSS( POSCSS (GetClassName(oButton1), CSS_BTN_FOCAL ))

	oButton2 := TButton():New( nHeight-20,nWidth-115,"Cancelar",oPnlFull,bCloseDlg,050,014,,,,.T.,,,,{|| .T.})
	oButton2:SetCSS( POSCSS (GetClassName(oButton2), CSS_BTN_ATIVO ))

	If lCodAcess
		oButCLib := TButton():New( nHeight-20,nWidth-180,"Cód.Libereção",oPnlFull,{||  AjustTela(lCodAcess) },060,014,,,,.T.,,,,{|| .T.}) //"+CRLF+"
		oButCLib:SetCSS( POSCSS (GetClassName(oButCLib), CSS_BTN_FOCAL ))

		oButUser := TButton():New( nHeight-20,nWidth-180,"Usuário/Senha",oPnlFull,{||  AjustTela(lCodAcess) },060,014,,,,.T.,,,,{|| .T.})
		oButUser:SetCSS( POSCSS (GetClassName(oButUser), CSS_BTN_FOCAL ))
	EndIf

	oDlgUsr:lCentered := .T.
	oDlgUsr:Activate(,,,.T.,{|| .T.},,{|| AjustTela(lCodAcess)})

Return(aRet)

//-------------------------------------------------------------------
/*/{Protheus.doc} AjustTela
Ajusta tela, conforme nTpLib
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function AjustTela(lCodAcess)

	If !lCodAcess
		nTpLib := 2 // ->>Usuário/Senha
		Return
	EndIf

	If nTpLib == 1
		oSayUser:Show()
		oGetUser:Show()
		oSaySenha:Show()
		oGetSenha:Show()
		oButCLib:Show()
		oSayCLib:Hide()
		oGetCLib:Hide()
		oButUser:Hide()
		nTpLib := 2 // ->>Usuário/Senha
	Else
		oSayUser:Hide()
		oGetUser:Hide()
		oSaySenha:Hide()
		oGetSenha:Hide()
		oButCLib:Hide()
		oSayCLib:Show()
		oGetCLib:Show()
		oButUser:Show()
		nTpLib := 1 // ->>Código Liberação
	EndIf

	oPnlFull:Refresh()

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} BtnConfirma
Executa a função do botão confirma da tela
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function BtnConfirma(cNome,cSenha,cCodUs,cCodLib,aRetLg)

	Local lRet := .F.

	aRetLg:={}
	If nTpLib == 2 // ->>Usuário/Senha
		If lRet := ValidaLogin(cNome,cSenha,@cCodUs)
			aRetLg := {cCodUs,cNome}
		EndIf
	Else // ->>Código Liberação
		If lRet := UAppPost(cCodLib)
			aRetLg := {'XXXXXX',cCodLib}
		EndIf
	EndIf

Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} UAppPost
client HTTP publica o código de liberação em um servidor Web, utilizando o método POST
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function UAppPost(cCodLib)

	Local cUrlApp := SuperGetMv("MV_XURLAPP",,"") //URL da aprovação do código de liberação de alçadas
	Local nTimeOut := 120
	Local aHeadOut := {}
	Local cHeadRet := ""
	Local sPostRet := ""
	Local cPostParms := ""
	Local oRetJson
	Local cParamJson := "" //Ex.: '{"filial":"0101", "cod_liberacao":"0123654789123"}'
	Local lRet := .F.

	cParamJson := GetJson(cCodLib)
	cPostParms += cParamJson

	CursorWait()

	//tenta pela Classe Client de REST, utilizando o método POST
	oRestClient := FWRest():New(cUrlApp)
	oRestClient:setPath("")
	//oRestClient:nTimeOut := 720 //milisegundos (default 120)
	oRestClient:SetPostParams(cPostParms)
	aHeadOut := {}
	aAdd(aHeadOut, "content-type: application/json; charset=utf-8")
	aAdd(aHeadOut, "Accept: application/json")

	If oRestClient:POST(aHeadOut)
		sPostRet := oRestClient:GetResult()
	Else
		//tenta pela função que emular um client HTTP, utilizando o método POST
		aHeadOut := {}
		aAdd(aHeadOut, "content-type| application/json")
		aAdd(aHeadOut, "Accept| application/json")
		sPostRet := HttpCPost(cUrlApp,cPostParms,nTimeOut,aHeadOut,@cHeadRet)
		If !Empty(sPostRet)
			//conout("HttpCPost "+cUrlApp+" - Ok")
			cHelpLg := "Erro na Classe Client de REST - FWRest():POST."+CRLF+"Erro: " + oRestClient:GetLastError()
		EndIf
	EndIf

	If !Empty(sPostRet)
		//remove caracteres inválidos
		sPostRet := EncodeUTF8(sPostRet, "cp1252") //Texto -> UTF8
		sPostRet := DecodeUTF8(sPostRet, "cp1252") //UTF8 -> Texto

		oRetJson := JsonObject():new()
		ret := oRetJson:FromJson(sPostRet)

		If ValType(ret) == "U"
			If ValType(oRetJson['message']) == "C"
				If oRetJson['message'] == 'CODIGO VALIDO'
					lRet := .T.
				ElseIf oRetJson['message'] == 'CODIGO EXPIRADO'
					cHelpLg := "Código de Liberação expirado."
				ElseIf oRetJson['message'] == 'CODIGO INVALIDO'
					cHelpLg := "Código de Liberação inválido."
				EndIf
			Else
				cHelpLg := "Retorno json do webservice inválido."
			EndIf
		Else
			cHelpLg := "Falha ao popular JsonObject."+CRLF+"Erro: " + ret
		EndIf

		FreeObj(oRetJson)

	EndIf

	CursorArrow()

Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} GetJson
Cria o JSON que será enviado nos parametros requisição


JSON - Ex.:
{
	"filial": "0101",
	"cod_liberacao": "0123654789123"
}

@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function GetJson(cCodLib)

	Local bObject := {|| JsonObject():New()}
	Local oRetJson   := Eval(bObject)

	oRetJson["filial"]         := AllTrim(cFilAnt)
	oRetJson["cod_liberacao"]  := AllTrim(cCodLib)

Return (oRetJson:toJSON()) //exporta o objeto JSON para uma string em formato JSON.

//-------------------------------------------------------------------
/*/{Protheus.doc} ValidaLogin
Valida login e senha digitada
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function ValidaLogin(cNome,cSenha,cCod)

	Local lRet 		:= .T.
	Local aArea		:= GetArea()
	Local aPswRet	:= {}
	Local lFound 	:= .F.

	cHelpLg:= ""

	PswOrder(2) //Nome do Usuario
	if PswSeek(AllTrim(cNome),.T.)
		lFound := .T.
	endif
	PswOrder(1) //ID do Usuario
	if !lFound .AND. PswSeek(AllTrim(cNome),.T.)
		lFound := .T.
	endif

	If !lFound .OR. !PswName(AllTrim(cSenha))
		cHelpLg := "Usuário ou senha inválidos"
		lRet := .F.
	Else
		aPswRet := PswRet()
		cCod	:= aPswRet[1,1]

		If aPswRet[1][17] = .T.
			cHelpLg := "Usuário bloqueado!"
			lRet := .F.
		ElseIf !Empty(aPswRet[1][6]) .AND. DTOC(aPswRet[1][6]) < DTOC(MsDate())
			cHelpLg := "Senha Expirada!"
			lRet := .F.
		Else
			nLen 	:= Len(AllTrim(cEmpAnt + cFilAnt))
			If Len(aPswRet) >= 2 .AND. aScan(aPswRet[2][6], {|x| x == "@@@@"}) == 0 //Se nao tiver acesso a todas filiais, verifica a filial logada
				If (aScan(aPswRet[2][6], {|x| Substr(x,1,nLen) == Trim(cEmpAnt + cFilAnt) }) == 0) .AND. (aScan(aPswRet[2][6], {|x| AllTrim(x) == AllTrim(cEmpAnt) }) == 0)
					cHelpLg := "Usuário sem acesso à Empresa/Filial!"
					lRet := .F.
				EndIf
			EndIf
		EndIf
	EndIf

	oHelpLg:Refresh()
	RestArea(aArea)

Return(lRet)

/*/{Protheus.doc} TR037LOG
Grava log de alçadas e liberação de acesso

@type User Function
@author thebr
@since 26/09/2019
@version 1.0
@return nil
/*/
User Function TR037LOG(cChavLog, cUserLog, cDocLog, cMsgLog, nVlrLid)

	Local lRet := .T.
	Local aParam, xResult
	Local nCodRet := 0
	Local lHasConnect := .F.
	Local lHostError := .F.
	Local lLogAlc := SuperGetMv("ES_ALCLOG",,.T.) //habilita log alçadas

	Default nVlrLid := 0

	If !lLogAlc
		Return
	EndIf

	CursorWait()

	aParam := {cChavLog, cUserLog, cDocLog, cMsgLog, nVlrLid}
	aParam := {"U_TR037LCE",aParam}
	If FWHostPing() .AND. STBRemoteExecute("_EXEC_CEN", aParam,,,@xResult,/*cType*/,/*cKeyOri*/, @nCodRet )
		// Se retornar esses codigos siginifica que a central esta off
		lHasConnect := !(nCodRet == -105 .OR. nCodRet == -107 .OR. nCodRet == -104)
		// Verifica erro de execucao por parte do host
		//-103 : erro na execução ,-106 : 'erro deserializar os parametros (JSON)
		lHostError := (nCodRet == -103 .OR. nCodRet == -106)

		If lHostError
			//STFMessage("TR037LOG","STOP", "Erro de conexão central PDV: " + cValtoChar(nCodRet) )
			//STFShowMessage("TR037LOG")
			//Conout("TR037LOG - Erro de conexão central PDV: " + cValtoChar(nCodRet))
			lRet := .F.
		EndIf

	ElseIf nCodRet == -101 .OR. nCodRet == -108
		//STFMessage("TR037LOG","STOP", "Servidor PDV nao Preparado. Funcionalidade nao existe ou host responsavel não associado. Cadastre a funcionalidade e vincule ao Host da Central PDV: " + cValtoChar(nCodRet) )
		//STFShowMessage("TR037LOG")
		//Conout( "TR037LOG - Servidor PDV nao Preparado. Funcionalidade nao existe ou host responsavel não associado. Cadastre a funcionalidade e vincule ao Host da Central PDV: " + cValtoChar(nCodRet))
		lRet := .F.
	Else
		//STFMessage("TR037LOG","STOP", "Erro de conexão central PDV: " + cValtoChar(nCodRet) )
		//STFShowMessage("TR037LOG")
		//Conout("TR037LOG - Erro de conexão central PDV: " + cValtoChar(nCodRet))
		lRet := .F.
	EndIf

	lRet := lRet .AND. lHasConnect .AND. ValType(xResult)=="L" .AND. xResult

	CursorArrow()

Return

/*/{Protheus.doc} TR037LCE
Grava log de alçadas e liberação de acesso na Central PDV

@type User Function
@author Pablo C Nunes
@since 07/05/2020
@version 1.0
@return nil
/*/
User Function TR037LCE(cChavLog, cUserLog, cDocLog, cMsgLog, nVlrLid)

	Local lLogAlc := SuperGetMv("ES_ALCLOG",,.T.) //habilita log alçadas
	Default nVlrLid := 0

	If !lLogAlc
		Return .F.
	EndIf

	DbSelectArea("U0E")
	Reclock("U0E",.T.) //inclui

	U0E->U0E_FILIAL := xFilial("U0E")
	U0E->U0E_CHAVE := cChavLog
	U0E->U0E_DATA := Date()
	U0E->U0E_HORA := Time()
	U0E->U0E_USER := cUserLog
	U0E->U0E_DOC := cDocLog
	U0E->U0E_MSG := cMsgLog
	if U0E->(FieldPos("U0E_VLRLID")) > 0
		U0E->U0E_VLRLID := nVlrLid
	endif

	U0E->(MsUnlock())

	//U0E_FILIAL+U0E_CHAVE+DTOS(U0E_DATA)+U0E_HORA
	U_UREPLICA("U0E", 1, U0E->(U0E_FILIAL+U0E_CHAVE+DTOS(U0E_DATA)+U0E_HORA), "I")

Return .T.

/*/{Protheus.doc} TR037SDL
Valor usado de Limite de Crédito por Periodo (D=Diario;S=Semanal;M=Mensal)

@type User Function
@author Pablo C Nunes
@since 07/05/2020
@version 1.0
@return nil
/*/
User Function TR037SDL(cUserLog,cTpLim)

	Local nRet := 0
	Local cQuery := ""
	Local dDtAtual := Date()

	If Select("QRYU0E") > 0
		QRYU0E->(DbCloseArea())
	EndIf

	cQuery := "SELECT SUM(U0E.U0E_VLRLID) USADO"
	cQuery += 	" FROM " + RetSQLName("U0E") + " U0E"

	cQuery += " WHERE U0E.D_E_L_E_T_ = ' '"
	cQuery += " AND U0E.U0E_CHAVE = 'ALCDES'" //Desconto por Valor ou Percentual
	cQuery += " AND U0E.U0E_USER = '"+cUserLog+"'"

	If cTpLim == 'D' //D=Diario
		cQuery += " AND U0E.U0E_DATA >= '"+DtoS(dDtAtual)+"'"
	ElseIf cTpLim == 'S' //S=Semanal
		cQuery += " AND U0E.U0E_DATA >= '"+DtoS(DaySub(dDtAtual,7))+"'"
	ElseIf cTpLim == 'M' //M=Mensal
		cQuery += " AND U0E.U0E_DATA >= '"+DtoS(MonthSub(dDtAtual,1))+"'"
	EndIf

	cQuery += " GROUP BY U0E.U0E_FILIAL, U0E.U0E_CHAVE, U0E.U0E_USER"

	cQuery := ChangeQuery(cQuery)
	TcQuery cQuery NEW Alias "QRYU0E"

	If QRYU0E->(!EoF())
		nRet := QRYU0E->USADO
	EndIf
	QRYU0E->(DbCloseArea())

Return nRet
