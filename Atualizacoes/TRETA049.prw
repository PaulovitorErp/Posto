#INCLUDE 'PROTHEUS.CH'
#INCLUDE 'FWMVCDEF.CH'
#INCLUDE 'TOPCONN.CH'

/*/{Protheus.doc} TRETA049
Rotina de Acompanhamento de Histórico de Preços

27/07/2020 - Danilo
Alteração para escolher acompanhar histórioco de:
Preço Negociado - fonte TRETA49A
Preço Base  - fonte TRETA49B
Ao chamar rotina, é perguntado qual preço quer acompanhar o historico

@param xParam Parameter Description
@return xRet Return Description
@author Danilo
@since 06/04/2020
/*/
User function TRETA049(_lCadCli)

    Local lNgDesc := SuperGetMV("MV_XNGDESC",,.T.) //Ativa negociação pelo valor de desconto: U25_DESPBA
    Local nRet
    Default _lCadCli		:= .F. 

    if lNgDesc .AND. !_lCadCli
        nRet := Aviso("Histórioco de Preços", "Escolha qual visão deseja ter na rotina de acompanhamento de histórico de preços:", {"Preço Base", "Preço Negociado"}, 2)

        if nRet == 1
            U_TRETA49B(_lCadCli) //preço base
        else
            U_TRETA49A(_lCadCli) //preço negociado
        endif
    else
        U_TRETA49A(_lCadCli)
    endif

Return
