
Static aFiliais := {}

/*/{Protheus.doc} User Function PPIContr
Controlador de Sessao e Paginas

@type  Function
@author danilo
@since 02/04/2020
@version version
@param cPageLoad, char, pagina que irá carregar
/*/
User Function PPIContr(cPageLoad)

    Private cGrpEmp := GetJobProfString('grpemp','') //exemplo da tag: grpemp=02

    //verifico condiguraçao da tag grpemp no appserver.ini
    if empty(cGrpEmp)
        Return 'Configurar a sessao [grpemp] no ResponseJob do servidor.'
    endif
    
    //gravo a pagina solicitada, para abrir após login
    HTTPSESSION->PAGE_REQUEST := cPageLoad

    //tratamento de login do usuario.
    //se vazio, não logou, joga pagina login
    If HTTPSESSION->LOGIN==Nil .OR. empty(HTTPSESSION->LOGIN)

        //sempre carrega filiais quando nao esta logado
        aFiliais := {}
        OpenSm0(cGrpEmp)
        Select("SM0")
        While SM0->(!eof())
            if SM0->M0_CODIGO == cGrpEmp
                aadd(aFiliais, {Alltrim(SM0->M0_CODFIL), Alltrim(SM0->M0_CODFIL) + " - "+Alltrim(SM0->M0_FILIAL)})
            endif
            SM0->(DbSkip())
        enddo

        //paginas antes do acesso, referente a login
        do case 
        case cPageLoad == "login"
            Return H_PPILogin()
        case cPageLoad == "confirma_login"
            Return U_PPILogin()
        case cPageLoad == 'forgot-password'
            Return H_PPIForgot()
        case cPageLoad == 'confirma_forgot'
            Return U_PPIForgot()
        otherwise 
            //caso nao seja passada nenhuma pagina dessas acima, direciona para login
            Return H_PPILogin()
        Endcase
        
    Endif

    //abro ambiente na empresa esolhida no login da sessão
    If Select("SX2") == 0 .OR. cFilAnt <> HTTPSESSION->CFILANT
        RPCSetType(3)  // Nao comer licensa
        RpcClearEnv()
        RpcSetEnv(HTTPSESSION->CEMPANT, HTTPSESSION->CFILANT, HTTPSESSION->LOGIN, HTTPSESSION->USRPSW,"ESP")
    endif

    //verifico acesso usuario as filiais
    LoadFilial()

    //abrir paginas do menu, entre outras
    do case 
    case cPageLoad == 'index'
        Return H_PPIIndex()
    case cPageLoad == 'logout'
        Return U_PPILogout()
    case cPageLoad == 'setfilial'
        Return U_PPISetFilial()
    case cPageLoad == 'monitorabast'
        Return H_PPIAbPend()
    case cPageLoad == 'load_abast_pend'
        Return U_PPIAbPend()
    case cPageLoad == 'limitecredito'
        Return H_PPILimCred()
    case cPageLoad == 'busca_limite_cred'
        Return U_PPILimCred()
    case cPageLoad == 'busca_cliente'
        Return U_PPIAcClient()
    case cPageLoad == 'busca_produto'
        Return U_PPIAcProd()
    case cPageLoad == 'preconeg'
        Return H_PPIPrecoNeg()
    case cPageLoad == 'busca_preco_neg'
        Return U_PPIPrecoNeg()
    case cPageLoad == 'monitorcarga'
        Return H_PPIMonitCarga()
    case cPageLoad == 'refresh_monitorcarga'
        Return U_PPIMonitCarga(2)
    otherwise 
        //caso nao seja passada nenhuma pagina dessas acima, direciona para index, com mensagem de pagina nao encontrada
        HTTPSESSION->MSGTYPE := 'warning' //success, warning, info, danger
        HTTPSESSION->MSGTEXT := 'Pagina solicitada nao encontrada!' //texto da mensagem
        Return H_PPIIndex()
    Endcase

Return ""

//retorna o array aFiliais
User Function AspGetFil()
Return aFiliais

Static Function LoadFilial()
    
    Local aPswRet, nLen, nX

    //recarrega filiais caso tenha limpado array
    if empty(aFiliais)
        aFiliais := {}
        OpenSm0(cGrpEmp)
        Select("SM0")
        While SM0->(!eof())
            if SM0->M0_CODIGO == cGrpEmp
                aadd(aFiliais, {Alltrim(SM0->M0_CODFIL), Alltrim(SM0->M0_CODFIL) + " - "+Alltrim(SM0->M0_FILIAL)})
            endif
            SM0->(DbSkip())
        enddo
    endif

    //tratativa para acesso do usuario as filiais
    If HTTPSESSION->LOGIN!=Nil .AND. !empty(HTTPSESSION->LOGIN)

        PswOrder(2) //Nome do Usuario
        PswSeek(AllTrim(HTTPSESSION->LOGIN),.T.)
        aPswRet := PswRet()
        nLen 	:= Len(AllTrim(cEmpAnt + cFilAnt))
        If Len(aPswRet) >= 2 .AND. aScan(aPswRet[2][6], {|x| x == "@@@@"}) == 0 //Se nao tiver acesso a todas filiais, verifica a filial logada
            for nX := 1 to len(aFiliais)
                If (aScan(aPswRet[2][6], {|x| Substr(x,1,nLen) == Trim(cEmpAnt + aFiliais[nX][1] ) }) == 0) .AND. (aScan(aPswRet[2][6], {|x| AllTrim(x) == AllTrim(cEmpAnt) }) == 0)
                    aFiliais[nX][1] := "SEMACESSO"
                Endif
            next nX
            while (nX := aScan(aFiliais, {|x| x[1] == "SEMACESSO"})) > 0
                aDel(aFiliais, nX)
                aSize(aFiliais, len(aFiliais)-1)
            enddo
        Endif

    endif

Return

